import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:lottie/lottie.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  //-----speech to text--------
  bool listen = false;
  double voiceLevel = 20;
  SpeechToText speechToText = SpeechToText();
  // التحقق من صلاحية الميكروفون وطلبها إذا لزم الأمر

  Future<bool> _checkMicrophonePermission() async {
    // الحصول على حالة صلاحية الميكروفون
    PermissionStatus status = await Permission.microphone.status;

    // التحقق مما إذا كانت الصلاحية ممنوحة
    if (status.isGranted) {
      return true; // صلاحية الميكروفون ممنوحة
    } else if (status.isDenied || status.isPermanentlyDenied) {
      // طلب الصلاحية من المستخدم إذا كانت مرفوضة أو مرفوضة بشكل دائم
      PermissionStatus newStatus = await Permission.microphone.request();

      // التحقق من حالة الصلاحية بعد طلبها
      if (newStatus.isGranted) {
        return true; // صلاحية الميكروفون ممنوحة بعد الطلب
      }
    }

    // صلاحية الميكروفون مرفوضة أو لم يتم منحها
    return false;
  }

  micCheck() async {
    bool mic = await speechToText.initialize();
    if (!mic) {
      micCheck();
    }
  }

  getVoice() {
    if (!listen) {
      setState(() {
        listen = true;
      });
      speechToText.listen(
        listenFor: Duration(minutes: 10),
        partialResults: false,
        onResult: (result) {
          getChatGeminiText(result.toString());

          setState(() {
            listen = false;
          });
        },
        onSoundLevelChange: (level) {
          setState(() {
            voiceLevel = max(20, level * 5);
          });
        },
      );
    } else {
      setState(() {
        listen = false;
        voiceLevel = 20;
      });
      speechToText.stop();
    }
  }

  //-----speech to text--------
  //-----Gemini ai-------
  int step = 0;
  String apiKey = "AIzaSyBjACJlHtAuESkYoHNSW8WlaU2gTty_yXI";
  getChatGeminiText(String str) {
    print("Str: : $str");
    setState(() {
      step = 1; //loading
    });
    Gemini gemini = Gemini.instance;
    gemini.text(str).then(
      (value) {
        setState(() {
          step = 2; //loaded
        });
        print("==============================");
        print("${value!.output.toString()}");
        flutterTts.speak(value!.output.toString());
      },
    );
  }

  //----- text to speech --------
  //-----Gemini ai--------
  FlutterTts flutterTts = FlutterTts();
  initTts() async {
    await flutterTts.awaitSpeakCompletion(true);
    flutterTts.setStartHandler(() {});
    flutterTts.setCompletionHandler(() {});
  }

  cancelSpeech() {
    flutterTts.stop();
    setState(() {
      listen = false;
      step = 0;
    });
  }

  @override
  void initState() {
    super.initState();
    Gemini.init(apiKey: apiKey);
    _checkMicrophonePermission();
    micCheck();
    initTts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
              onPressed: () {},
              icon: const Icon(
                CupertinoIcons.exclamationmark_circle,
                color: Colors.white,
              ))
        ],
      ),
      body: SizedBox(
        width: MediaQuery.sizeOf(context).width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Spacer(
              flex: 1,
            ),
            step == 1
                ? Lottie.asset('assets/loading.json',
                    height: (MediaQuery.sizeOf(context).width / 2.6) * 2.6,
                    width: (MediaQuery.sizeOf(context).width / 2.6) * 2.6,
                    fit: BoxFit.cover)
                : step == 0
                    ? CircleAvatar(
                        radius: MediaQuery.sizeOf(context).width / 2.6,
                        backgroundColor: Colors.white,
                      )
                    : Padding(
                        padding: const EdgeInsets.only(right: 50, left: 50),
                        child: Lottie.asset('assets/sound.json'),
                      ),
            SizedBox(
              height: 30,
            ),
            Text(
              step == 1
                  ? "loading"
                  : listen
                      ? "Listening..."
                      : "Tap to start",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w400),
            ),
            const Spacer(
              flex: 1,
            ),
            Container(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Container(
                      height: 55,
                      width: 55,
                      decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(30)),
                      child: IconButton(
                          onPressed: () {
                            if (listen == false) {
                              getVoice();
                            }
                          },
                          icon: Icon(
                            step == 2
                                ? Icons.square_rounded
                                : listen
                                    ? Icons.pause
                                    : Icons.play_arrow,
                            size: 25,
                            color: Colors.white,
                          ))),
                  Row(
                    children: [
                      Icon(
                        step != 0 ? Icons.mic_off : Icons.mic,
                        color: Colors.white,
                      ),
                      SizedBox(
                        width: 2,
                      ),
                      if (step == 0)
                        Row(
                          children: [
                            AnimatedContainer(
                              margin: EdgeInsets.only(right: 3),
                              duration: const Duration(milliseconds: 200),
                              height: listen ? voiceLevel * 1.1 : 20,
                              width: 15,
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(30)),
                            ),
                            AnimatedContainer(
                              margin: EdgeInsets.only(right: 3),
                              duration: const Duration(milliseconds: 200),
                              height: listen ? voiceLevel * 1.2 : 20,
                              width: 15,
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(30)),
                            ),
                            AnimatedContainer(
                              margin: EdgeInsets.only(right: 3),
                              duration: const Duration(milliseconds: 200),
                              height: listen ? voiceLevel * 1.5 : 20,
                              width: 15,
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(30)),
                            ),
                            AnimatedContainer(
                              margin: EdgeInsets.only(right: 3),
                              duration: const Duration(milliseconds: 200),
                              height: listen ? voiceLevel * 1.2 : 20,
                              width: 15,
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(30)),
                            ),
                          ],
                        )
                    ],
                  ),
                  Container(
                      height: 55,
                      width: 55,
                      decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(30)),
                      child: IconButton(
                          onPressed: () {
                            cancelSpeech();
                          },
                          icon: const Icon(
                            Icons.close,
                            size: 25,
                            color: Colors.white,
                          ))),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
