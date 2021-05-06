import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(RecordAudio());
}

class RecordAudio extends StatelessWidget {
  const RecordAudio({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Audio Recorder and Player",
      debugShowCheckedModeBanner: false,
      home: RecordAudioHome(),
    );
  }
}

class RecordAudioHome extends StatelessWidget {
  const RecordAudioHome({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Audio Recorder and Player"),
        centerTitle: true,
      ),
      endDrawer: Drawer(),
      body: RecordAudioCore(),
    );
  }
}

class RecordAudioCore extends StatefulWidget {
  const RecordAudioCore({Key key}) : super(key: key);

  @override
  _RecordAudioCoreState createState() => _RecordAudioCoreState();
}

class _RecordAudioCoreState extends State<RecordAudioCore> {
  FlutterSoundPlayer pl = new FlutterSoundPlayer();
  FlutterSoundRecorder rc = new FlutterSoundRecorder();

  final savePath = "/storage/emulated/0/Recordings";
  String leftButtonTitle, middleButtonTitle, rightButtonTitle;
  String timeStamp;
  PermissionStatus useMic, useExt;

  String recordingNameGen() {
    var currTimestamp = DateTime.now();
    String doubleDigit(int dD, int zero) => dD.toString().padLeft(zero, "0");
    String currMonth = doubleDigit(currTimestamp.month, 2);
    String currDay = doubleDigit(currTimestamp.day, 2);
    String currMin = doubleDigit(currTimestamp.minute, 2);
    String currSec = doubleDigit(currTimestamp.second, 2);
    return timeStamp =
        "${currTimestamp.year}$currMonth$currDay\_${currTimestamp.hour}$currMin$currSec";
  }

  void requestDirPermission() async {
    useExt = await Permission.manageExternalStorage.request();
    print(useExt);
    createRecordingDir();
  }

  void createRecordingDir() async {
    final Directory dir = new Directory('/storage/emulated/0/Recordings/');
    if (useExt == PermissionStatus.granted) {
      bool isNotAvail = !await dir.exists();
      if (isNotAvail) {
        dir.create(recursive: true);
        print("Folder created");
      }
      print("folder was not created or has already been if folder created text doesn't appear above this one");
    }
    print("Folder is created should appear above this one if it works");
  }

  void recordAudio() async {
    if (rc.isRecording || rc.isPaused) {
      return null;
    } else {
      useMic = await Permission.microphone.request();
      if (useMic != PermissionStatus.granted) {
        throw RecordingPermissionException("Microphone permission denied!");
      }
      if (useExt != PermissionStatus.granted) {
        throw (value) => {print("External storage permission denied!, $value")};
      }
      recordingNameGen();
      rc = await FlutterSoundRecorder().openAudioSession();
      await rc.startRecorder(
          toFile: "$savePath/$timeStamp.aac", codec: Codec.aacADTS, bitRate: 320000 ,numChannels: 2, sampleRate: 44100);
    }
  }

  void pauseRecord() async {
    if (rc.isStopped) {
      return null;
    } else {
      middleButtonTitle = "Resume";
      await rc.pauseRecorder();
    }
  }

  void resumeRecord() async {
    if (rc.isStopped) {
      return null;
    } else {
      middleButtonTitle = "Pause";
      await rc.resumeRecorder();
    }
  }

  void stopRecord() async {
    if (rc.isStopped) {
      return null;
    } else {
      setState(() {
        middleButtonTitle = "Pause";
      });
      // showPopup("Audio recording saved",
      //     "Audio recording $timeStamp is saved into $savePath", "Okay");
      await rc.stopRecorder();
      rc.closeAudioSession();
      pl = null;
    }
  }

  Future<void> dirPermissionReq() async {
    return showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
              title: Text("Accessing storage"),
              content: SingleChildScrollView(
                child: ListBody(children: <Widget>[
                  Text(
                      "Application will now request for permission to access storage")
                ]),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text("Okay"),
                  onPressed: () {
                    requestDirPermission();
                    Navigator.pop(context);
                  },
                )
              ]);
        });
  }

  @override
  void dispose() {
    if (rc != null) {
      rc.closeAudioSession();
      pl = null;
    }
    super.dispose();
  }

  @override
  void initState() {
    // SchedulerBinding.instance.addPostFrameCallback((timeStamp) async {
    //   bool isShown = await Permission.manageExternalStorage.shouldShowRequestRationale;
    //   dirPermissionReq();
    //   print(timeStamp.inMilliseconds);
    //   print(isShown);
    // });
    requestDirPermission();
    leftButtonTitle = "Record";
    middleButtonTitle = "Pause";
    rightButtonTitle = "Stop";
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    recordAudio();
                  });
                },
                child: Text(leftButtonTitle),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    switch (middleButtonTitle) {
                      case "Pause":
                        pauseRecord();
                        break;
                      case "Resume":
                        resumeRecord();
                        break;
                    }
                  });
                },
                child: Text(middleButtonTitle),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    stopRecord();
                  });
                },
                child: Text(rightButtonTitle),
              ),
            )
          ],
        ));
  }
}
