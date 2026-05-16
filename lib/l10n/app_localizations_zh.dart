// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '快存相机';

  @override
  String get howToUse => '如何使用？';

  @override
  String get helpContent =>
      '首先，点击右下角的按钮，输入图片保存路径和名称，创建一个新的拍照键；然后，点击创建的按钮，即可拍照并保存到按钮对应的路径中。\n注意：在有的手机上，新建的文件夹需要重启以后才会被图库应用识别到。';

  @override
  String get createANewSaver => '创建新的拍照键';

  @override
  String get editSaver => '编辑拍照键';

  @override
  String get delete => '删除';

  @override
  String get saverPath => '图片保存路径';

  @override
  String get selectPath => '选择保存路径';

  @override
  String get saverName => '拍照键名称';

  @override
  String get saverNameDescription => '输入此拍照键的名称';

  @override
  String get fileName => '文件名称';

  @override
  String get ok => '确定';

  @override
  String get cancel => '取消';

  @override
  String get preview => '预览';

  @override
  String get importAllExistingAlbums => '导入全部已有相册';

  @override
  String get contactDeveloper => '联系开发者';

  @override
  String get browseSourceCode => '浏览源码';

  @override
  String get notYetImplemented => '尚未实现';

  @override
  String get saverPathExisted => '❌已经存在这个路径的拍照键了';

  @override
  String get thankForCharlie => '🎉感谢Charlie Sierra为本App提供的灵感！';

  @override
  String get removeSaver => '删除拍照键?';

  @override
  String get name => '名称';

  @override
  String get path => '路径';

  @override
  String get photoName => '照片名称';

  @override
  String get photoNameDescription => '输入照片名称';

  @override
  String get more => '更多';

  @override
  String get photoIndex => '序号';

  @override
  String get photoTimestamp => '时间';

  @override
  String get photoNameExample => '照片名称示例';

  @override
  String get moreDialogFinished => '照片名称设置完毕';

  @override
  String get buy_me_coffee => '买杯咖啡给作者';

  @override
  String get color_scheme => '颜色主题';

  @override
  String get resolution_low => '低';

  @override
  String get resolution_medium => '中';

  @override
  String get resolution_high => '高';

  @override
  String get resolution_vh => '超高';

  @override
  String get resolution_uh => '极高';

  @override
  String get resolution_max => '最大';

  @override
  String get editSaverButton => '编辑拍照键';

  @override
  String get openAlbumDirectory => '预览文件夹';

  @override
  String photoSavedTo(String path) {
    return '图片已保存到$path';
  }
}
