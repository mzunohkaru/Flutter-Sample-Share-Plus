import 'dart:io';
import 'dart:ui';

import 'package:aura_box/aura_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final convertWidgetToImageKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Share Plus'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RepaintBoundary(
              key: convertWidgetToImageKey,
              child: AuraBox(
                decoration: BoxDecoration(
                  color: Colors.blueGrey.shade100,
                  borderRadius: const BorderRadius.all(
                    Radius.circular(16),
                  ),
                ),
                spots: [
                  AuraSpot(
                    color: Colors.amber,
                    radius: 100,
                    alignment: const Alignment(0.1, 0.1),
                    blurRadius: 30,
                  ),
                  AuraSpot(
                    color: Colors.red.shade400,
                    radius: 90,
                    alignment: const Alignment(-0.1, -0.1),
                    blurRadius: 20,
                  ),
                ],
                child: SizedBox(
                  height: 200,
                  child: Center(
                    child: Text(
                      'Aura Box',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 48,
                        color: Theme.of(context).colorScheme.surface,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 24,
            ),
            ElevatedButton(
              onPressed: () {
                shareWidgetImage(globalKey: convertWidgetToImageKey);
              },
              child: const Text('Widgetをシェア'),
            ),
            ElevatedButton(
              onPressed: () {
                Share.share('このアプリは、○○○○をユーザーに.....');
              },
              child: const Text('テキストをシェア'),
            ),
            ElevatedButton(
              onPressed: shareAssetImage,
              child: const Text('assetsフォルダの画像をシェア'),
            ),
            ElevatedButton(
              onPressed: shareNetworkImage,
              child: const Text('インターネットの画像をシェア'),
            ),
          ],
        ),
      ),
    );
  }

  Future shareAssetImage() async {
    // 画像を取得する。
    final image = await rootBundle
        .load('assets/image.png'); // rootBundle.load()で、assetsフォルダから画像を取得する。
    // 画像をバッファに格納する。
    final buffer = image.buffer; // image.bufferで、画像をバッファに格納する。
    // 画像をシェアする。
    Share.shareXFiles(
      [
        XFile.fromData(
          // XFile.fromDataの引数には、Uint8List型のデータを渡す。
          buffer.asUint8List(
            // buffer.asUint8List()で、Uint8List型のデータを取得する。
            image.offsetInBytes, // image.offsetInBytesで、画像のバイトオフセットを取得する。
            image.lengthInBytes, // image.lengthInBytesで、画像のバイト長を取得する。
          ),
          name: 'Photo.png',
          mimeType: 'image/png',
        ),
      ],
      subject: 'Flutter Logo',
    );
  }

  Future shareNetworkImage() async {
    // httpを使用してDashの画像をシェアする。
    const imageNetwork =
        'https://upload.wikimedia.org/wikipedia/commons/4/4f/Dash%2C_the_mascot_of_the_Dart_programming_language.png';
    final url = Uri.parse(imageNetwork);
    final response = await http.get(url);
    Share.shareXFiles([
      XFile.fromData(
        response.bodyBytes,
        name: 'Dash.png',
        mimeType: 'image/png',
      ),
    ], subject: 'Flutter 3');
  }

  /// Widgetを画像へ変換
  Future<ByteData?> exportWidgetToImage(GlobalKey globalKey) async {
    final boundary =
        globalKey.currentContext?.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(
      pixelRatio: 3,
    );
    final byteData = await image.toByteData(
      format: ImageByteFormat.png,
    );
    return byteData;
  }

  /// 画像をローカルパスに保存
  Future<File> getApplicationDocumentsFile(
    String text,
    List<int> imageData,
  ) async {
    final directory = await getApplicationDocumentsDirectory();

    final exportFile = File('${directory.path}/$text.png');
    if (!await exportFile.exists()) {
      await exportFile.create(recursive: true);
    }
    final file = await exportFile.writeAsBytes(imageData);
    return file;
  }

  /// Widget画像をシェアする
  void shareWidgetImage({
    required GlobalKey globalKey,
  }) async {
    // globalKeyからWidgetを画像へ変換
    final byteData = await exportWidgetToImage(globalKey);
    if (byteData == null) {
      return;
    }
    // 画像をUint8Listへ変換
    final widgetImageBytes = byteData.buffer
        .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
    // 画像をローカルパスに保存
    final applicationDocumentsFile = await getApplicationDocumentsFile(
      globalKey.toString(),
      widgetImageBytes,
    );
    final path = applicationDocumentsFile.path;
    // 画像をシェア
    await Share.shareFiles(
      [path],
    );
  }
}
