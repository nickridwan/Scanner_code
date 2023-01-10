import 'dart:developer';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:osbondgym_dash/controllers/route/n_route.dart';
import 'package:osbondgym_dash/models/club_model.dart';
import 'package:osbondgym_dash/theme.dart';
import 'package:osbondgym_dash/views/widgets/snackbar.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

void main() {
    runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      useInheritedMediaQuery: true,
      title: 'Flutter Demo',
      theme: ThemeData(scaffoldBackgroundColor: AppColor.kLineDarkColor),
      home: const CheckinPage(),
    );
  }
}

class CheckinPage extends StatefulWidget {
  const CheckinPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _CheckinPageState();
}

class _CheckinPageState extends State<CheckinPage> {
  Barcode? result;
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  bool onflash = false;

  List<ClubModel> clubId = [
    ClubModel(id: "test 1"),
    ClubModel(id: "test 2"),
    ClubModel(id: "test 3"),
    ClubModel(id: "test 4"),
    ClubModel(id: "test 5"),
    ClubModel(id: "test 6"),
    ClubModel(id: "test 7"),
    ClubModel(id: "test 8"),
    ClubModel(id: "test 9"),
    ClubModel(id: "test 10"),
  ];

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isIOS) {
      controller!.pauseCamera();
    } else if (Platform.isAndroid) {
      controller!.resumeCamera();
    }
  }

  @override
  void initState() {
    super.initState();
    controller!.resumeCamera();
  }

  formatClubId() {
    // ignore: unrelated_type_equality_checks
    if (result!.code.toString().isNotEmpty) {
      controller!.pauseCamera();
      controller!.dispose();
      if (clubId
          .where((element) => element.id == result!.code)
          .toList()
          .isNotEmpty) {
        NavigationRoute.routeBack(context);
        statusAlert(context, "Berhasil Checkin", true);
      } else {
        NavigationRoute.routeBack(context);
        toashAlert(
            context, "QR Code Salah", CupertinoIcons.xmark_circle, false);
      }
    } else {
      toashAlert(context, "QR Code Error", CupertinoIcons.xmark_circle, false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: _buildQrView(context),
          ),
          Positioned(
            bottom: 0,
            left: 50,
            right: 50,
            child: FittedBox(
              fit: BoxFit.contain,
              child: Column(
                children: <Widget>[
                  result != null
                      ? Text(
                          textAlign: TextAlign.start,
                          '${result!.code}',
                          style: Style.whiteTextStyle.copyWith(fontSize: 5),
                        )
                      : Text(
                          'Scan a code',
                          style: Style.whiteTextStyle.copyWith(fontSize: 5),
                        ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      SizedBox(
                        child: FutureBuilder(
                          future: controller?.getFlashStatus(),
                          builder: (context, snapshot) {
                            return IconButton(
                              onPressed: () async {
                                await controller?.toggleFlash();
                                log("flash : ${snapshot.data} \nonflash : $onflash");
                                setState(() {
                                  onflash = !onflash;
                                });
                              },
                              icon: Icon(
                                onflash ? Icons.flash_off : Icons.flash_on,
                                size: 10.0,
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(
                        child: FutureBuilder(
                          future: controller?.getCameraInfo(),
                          builder: (context, snapshot) {
                            if (snapshot.data != null) {
                              return IconButton(
                                onPressed: () async {
                                  await controller?.flipCamera();
                                  setState(() {});
                                },
                                icon: const Icon(
                                  Icons.flip_camera_ios,
                                  size: 10.0,
                                ),
                              );
                            } else {
                              return CircularProgressIndicator(
                                color: AppColor.kWhiteColor,
                              );
                            }
                          },
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildQrView(BuildContext context) {
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
            MediaQuery.of(context).size.height < 400)
        ? 150.0
        : 300.0;
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
          borderColor: Colors.red,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: scanArea),
      onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        result = scanData;
      });
      formatClubId();
    });
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    log('${DateTime.now().toIso8601String()}_onPermissionSet $p');
    if (!p) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('no Permission')),
      );
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
