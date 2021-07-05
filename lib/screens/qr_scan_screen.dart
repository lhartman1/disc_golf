import 'dart:io';

import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

import '../db/firebase_helper.dart';

class QRScanScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _QRScanScreenState();
}

class _QRScanScreenState extends State<QRScanScreen> {
  Barcode? result;
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  // In order to get hot reload to work we need to pause the camera if the platform
  // is android, or resume the camera if the platform is iOS.
  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    }
    controller!.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Join Game by QR Code'),
      ),
      body: Stack(
        children: [
          _buildQrView(context),
          if (result != null)
            // TODO: make this better with loading indicator or something
            FractionallySizedBox(
              // alignment: Alignment.center,
              heightFactor: 0.4,
              widthFactor: 1,
              child: Center(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        result?.code ?? 'Unknown',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headline6,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQrView(BuildContext context) {
    // For this example we check how width or tall the device is and change the scanArea and overlay accordingly.
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
            MediaQuery.of(context).size.height < 400)
        ? 150.0
        : 300.0;
    // To ensure the Scanner view is properly sizes after rotation
    // we need to listen for Flutter SizeChanged notification and update controller
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
          borderColor: Colors.red,
          borderRadius: 10,
          borderLength: 30,
          borderWidth: 10,
          cutOutSize: scanArea),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) {
      if (result != null) return;

      setState(() {
        result = scanData;
      });

      FirebaseHelper.addUserToMatch(
              FirebaseHelper.getUserId() ?? '<unknown>', scanData.code)
          .then((value) {
        if (value) {
          Navigator.pop(context);
        } else {
          result = null;
          // TODO: show snackbar on failure?
        }
      });
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
