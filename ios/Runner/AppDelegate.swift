import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // Setup file save channel
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "IosFileSavePlugin") {
      IosFileSavePlugin.register(with: registrar)
      NSLog("IosFileSaveService: Registered")
    }

    // Register path picker channel
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "PathPickerPlugin") {
      let channel = FlutterMethodChannel(name: "com.snapsaver/path_picker", binaryMessenger: registrar.messenger())
      channel.setMethodCallHandler { [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
        if call.method == "pickDirectory" {
          self?.pickDirectory(result: result)
        } else if call.method == "getAppDocumentsPath" {
          let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
          result(paths.first?.path)
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
    }
  }

  private func pickDirectory(result: @escaping FlutterResult) {
    DispatchQueue.main.async {
      guard let rootVC = UIApplication.shared.keyWindow?.rootViewController else {
        result(FlutterError(code: "NO_ROOT_VC", message: "No root view controller", details: nil))
        return
      }

      // Get our App's Documents directory
      let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

      // Create a folder picker within our documents - use iOS 14+ API
      let picker: UIDocumentPickerViewController
      if #available(iOS 14.0, *) {
        picker = UIDocumentPickerViewController(forOpeningContentTypes: [.folder])
        picker.directoryURL = documentsURL
      } else {
        picker = UIDocumentPickerViewController(documentTypes: ["public.folder"], in: .open)
      }
      picker.accessibilityHint = "Select a folder within the app's documents directory"

      let delegate = DocumentPickerDelegate(result: result)
      picker.delegate = delegate
      objc_setAssociatedObject(picker, "delegate", delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

      rootVC.present(picker, animated: true)
    }
  }
}

class DocumentPickerDelegate: NSObject, UIDocumentPickerDelegate {
  let result: FlutterResult

  init(result: @escaping FlutterResult) {
    self.result = result
  }

  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    guard let url = urls.first else {
      result(nil)
      return
    }

    // Security check: ensure the selected path is within our sandbox
    // Use standardized paths to handle /var -> /private/var symlink
    let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    let normalizedDocumentsPath = documentsURL.standardizedFileURL.path
    let normalizedSelectedPath = url.standardizedFileURL.path

    NSLog("PathPicker: documentsURL=%@", normalizedDocumentsPath)
    NSLog("PathPicker: selectedURL=%@", normalizedSelectedPath)
    NSLog("PathPicker: hasPrefix=%@", normalizedSelectedPath.hasPrefix(normalizedDocumentsPath) ? "YES" : "NO")

    if normalizedSelectedPath.hasPrefix(normalizedDocumentsPath) {
      // Start accessing security-scoped resource to persist access
      let didStart = url.startAccessingSecurityScopedResource()
      if didStart {
        result(url.path)
        url.stopAccessingSecurityScopedResource()
      } else {
        // Even if we can't get persistent access, try direct access
        if FileManager.default.isReadableFile(atPath: url.path) {
          result(url.path)
        } else {
          result(FlutterError(code: "ACCESS_DENIED", message: "Cannot access selected directory", details: nil))
        }
      }
    } else {
      result(FlutterError(code: "OUTSIDE_SANDBOX", message: "Selected directory is outside app sandbox", details: nil))
    }
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    result(nil)
  }
}

// Flutter Plugin for file saving
public class IosFileSavePlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "com.snapsaver/file_save", binaryMessenger: registrar.messenger())
    let instance = IosFileSavePlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "saveFile" else {
      result(FlutterMethodNotImplemented)
      return
    }

    guard let args = call.arguments as? [String: Any],
          let sourcePath = args["sourcePath"] as? String,
          let destinationDirectory = args["destinationDirectory"] as? String,
          let fileName = args["fileName"] as? String else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "Missing required arguments", details: nil))
      return
    }

    saveFile(sourcePath: sourcePath, destinationDirectory: destinationDirectory, fileName: fileName, result: result)
  }

  private func saveFile(sourcePath: String, destinationDirectory: String, fileName: String, result: @escaping FlutterResult) {
    let fileManager = FileManager.default
    NSLog("IosFileSaveService: sourcePath=%@", sourcePath)
    NSLog("IosFileSaveService: destinationDirectory=%@", destinationDirectory)
    NSLog("IosFileSaveService: fileName=%@", fileName)

    // Get the directory URL
    let directoryURL = URL(fileURLWithPath: destinationDirectory)

    // First check if directory is accessible
    var isDirectory: ObjCBool = false
    guard fileManager.fileExists(atPath: destinationDirectory, isDirectory: &isDirectory) else {
      NSLog("IosFileSaveService: Directory does not exist")
      result(FlutterError(code: "DIR_NOT_EXISTS", message: "Directory does not exist: \(destinationDirectory)", details: nil))
      return
    }

    guard isDirectory.boolValue else {
      NSLog("IosFileSaveService: Path is not a directory")
      result(FlutterError(code: "NOT_A_DIRECTORY", message: "Path is not a directory: \(destinationDirectory)", details: nil))
      return
    }

    // Check write permissions
    if !fileManager.isWritableFile(atPath: destinationDirectory) {
      NSLog("IosFileSaveService: Directory is not writable")

      // Try to fix permissions by creating a test file
      let testFileURL = directoryURL.appendingPathComponent(".write_test_\(UUID().uuidString)")
      do {
        try "test".write(to: testFileURL, atomically: true, encoding: .utf8)
        try fileManager.removeItem(at: testFileURL)
        NSLog("IosFileSaveService: Directory is actually writable despite check")
      } catch {
        NSLog("IosFileSaveService: Directory is truly not writable - %@", error.localizedDescription)
        result(FlutterError(code: "PERMISSION_DENIED", message: "No write permission for directory: \(destinationDirectory)", details: nil))
        return
      }
    }

    // Try with security-scoped resource
    let didStartAccessing = directoryURL.startAccessingSecurityScopedResource()
    NSLog("IosFileSaveService: didStartAccessing=%@", didStartAccessing ? "true" : "false")

    defer {
      if didStartAccessing {
        directoryURL.stopAccessingSecurityScopedResource()
      }
    }

    let destinationURL = directoryURL.appendingPathComponent(fileName)
    let sourceURL = URL(fileURLWithPath: sourcePath)

    do {
      if fileManager.fileExists(atPath: destinationURL.path) {
        try fileManager.removeItem(at: destinationURL)
      }

      try fileManager.copyItem(at: sourceURL, to: destinationURL)
      NSLog("IosFileSaveService: SUCCESS")
      result(destinationURL.path)
    } catch {
      NSLog("IosFileSaveService: SAVE_FAILED - %@", error.localizedDescription)
      result(FlutterError(code: "SAVE_FAILED", message: "Failed to save file: \(error.localizedDescription)", details: nil))
    }
  }
}