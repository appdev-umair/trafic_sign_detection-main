import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:camera/camera.dart';
import 'package:fluid_dialog/fluid_dialog.dart';
import 'package:flutter/material.dart';
import 'package:ftoast/ftoast.dart';
import 'package:tflite/tflite.dart';

List<CameraDescription>? cameras;
Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Sign Sense"),
        actions: [
          IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => FluidDialog(
                    rootPage: FluidDialogPage(
                      alignment: Alignment.center,
                      builder: (context) => const SecondDialogPage(),
                    ),
                  ),
                );
              },
              icon: Icon(
                Icons.info_outline_rounded,
                size: 35,
              ))
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => Home()),
          );
        },
        label: Text("Real Time Detection"),
        icon: Icon(Icons.arrow_forward),
      ),
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              "assets/logo.png",
              width: 100,
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const SizedBox(height: 70.0),
                DefaultTextStyle(
                  style: TextStyle(
                      color: Colors.deepPurple,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                  child: AnimatedTextKit(
                    isRepeatingAnimation: true,
                    repeatForever: true,
                    animatedTexts: [
                      RotateAnimatedText('SignSense'),
                      RotateAnimatedText('An Alert System'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SecondDialogPage extends StatelessWidget {
  const SecondDialogPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.deepPurple),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text(
                        "Ayesha Sadiqa",
                        style: TextStyle(
                            color: Color.fromARGB(255, 255, 255, 255),
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "19011519-082",
                        style: TextStyle(
                            color: Color.fromARGB(255, 255, 255, 255),
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 20),
                      Text(
                        "Supervisors",
                        style: TextStyle(
                            color: Color.fromARGB(255, 250, 250, 250),
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "Dr. Naveed Anwar Butt",
                        style: TextStyle(
                            color: Color.fromARGB(255, 250, 250, 250),
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "Dr. Muhammad Usman Ali",
                        style: TextStyle(
                            color: Color.fromARGB(255, 250, 250, 250),
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                    ]),
              ),
            ),
            TextButton(
              onPressed: () => DialogNavigator.of(context).close(),
              child: const Text('Okay'),
            ),
          ],
        ),
      ),
    );
  }
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  CameraImage? cameraImage;
  CameraController? cameraController;
  String output = "";

  final player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    loadModel();
    loadCamera();
  }

  void loadCamera() {
    cameraController = CameraController(cameras![0], ResolutionPreset.medium);
    cameraController!.initialize().then((value) {
      if (!mounted) {
        return;
      } else {
        setState(() {
          cameraController!.startImageStream((CameraImage image) {
            cameraImage = image;
            runModel();
          });
        });
      }
    });
  }

  Future<void> runModel() async {
    if (cameraImage != null) {
      var predictions = await Tflite.runModelOnFrame(
        bytesList: cameraImage!.planes.map((plane) {
          return plane.bytes;
        }).toList(),
        imageHeight: cameraImage!.height,
        imageWidth: cameraImage!.width,
        imageMean: 200,
        imageStd: 200,
        rotation: 90,
        numResults: 1,
        threshold: 0.5,
        asynch: true,
      );

      for (var element in predictions!) {
        setState(() {
          output = element['label'];
          if (output != "NOT A SIGN") {
            player.play(AssetSource("beep.mp3"));
          } else {
            player.pause();
          }
        });
      }
    }
  }

  void loadModel() async {
    await Tflite.loadModel(
        model: "assets/model.tflite", labels: "assets/labels.txt");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      backgroundColor: Color.fromARGB(255, 255, 255, 255),
      body: Column(children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.78,
          width: MediaQuery.of(context).size.width,
          child:
              cameraController == null || !cameraController!.value.isInitialized
                  ? Container(
                      height: 100,
                      color: Color.fromARGB(255, 0, 0, 0),
                    )
                  : AspectRatio(
                      aspectRatio: cameraController!.value.aspectRatio,
                      child: CameraPreview(cameraController!),
                    ),
        ),
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.1,
          child: Center(
            child: Text(
              output,
              style: const TextStyle(
                  color: Colors.deepPurple,
                  fontWeight: FontWeight.bold,
                  fontSize: 20),
            ),
          ),
        )
      ]),
    );
  }
}
