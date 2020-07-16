import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:tflite/tflite.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ZooPass',
      home: MyHomePage(),
    );
  }
}


class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File _image;
  List _recognitions;
  bool _busy = false;
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _busy = true;

    loadModel().then((value) {
      setState(() {
        _busy = false;
      });
    });
  }


  Future getImage() async {
    final pickedFile = await picker.getImage(source: ImageSource.camera);
    if(pickedFile == null) return;

    setState(() {
      _image = File(pickedFile.path);
      _busy = false;
    });

    await recognizeImage(File(pickedFile.path));
  }

  Future loadModel() async {
    await Tflite.loadModel(
        model: "assets/model.tflite",
        labels: "assets/labels.txt",
        numThreads: 1 // defaults to 1
    );

  }

  Future recognizeImage(File image) async {
    var recognitions = await Tflite.runModelOnImage(
      path: image.path,
      numResults: 2,
      threshold: 0.5,
      imageMean: 127.5,
      imageStd: 127.5,
    );
    setState(() {
      _busy = false;
      _recognitions = recognitions;
    });

    print('Recognition Result: $_recognitions');
  }

  @override
  Widget build(BuildContext context) {

    List<Widget> stackChildren = [];
    Size size = MediaQuery.of(context).size;

    stackChildren.clear();

    stackChildren.add(Positioned(
      top: 0.0,
      left: 0.0,
      width: size.width,
      child: _image == null ? new Center(child: Text('Изображения не выбраны')) : Image.file(_image),
    ));

    stackChildren.add(Center(
      child: Column(
        children: _recognitions != null
            ? _recognitions.map((res) {
          return Text(
            "${_recognitions[0]["label"]}: ${_recognitions[0]["confidence"].toStringAsFixed(3)}",
            style: TextStyle(
              color: Colors.black,
              fontSize: 20.0,
              background: Paint()..color = Colors.white,
            ),
          );
        }).toList() : [],
      ),
    ));


    if (_busy) {
      stackChildren.add(const Opacity(
        child: ModalBarrier(dismissible: false, color: Colors.grey),
        opacity: 0.3,
      ));
      stackChildren.add(const Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('ZooPass'),
      ),
      body: Stack(
        children: stackChildren,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: getImage,
        tooltip: 'Pick Image',
        child: Icon(Icons.camera),
      ),
    );
  }

  @override
  void dispose() {
    Tflite.close();
    super.dispose();
  }
}



