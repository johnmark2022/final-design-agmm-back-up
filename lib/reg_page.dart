import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:signature/signature.dart';
import 'package:image_picker/image_picker.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'database_helper.dart';

class RegPageWidget extends StatefulWidget {
  const RegPageWidget({super.key});

  static String routeName = 'reg_page';
  static String routePath = '/regPage';

  @override
  State<RegPageWidget> createState() => _RegPageWidgetState();
}

class _RegPageWidgetState extends State<RegPageWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController textController = TextEditingController(
    text: 'ENTER CIF KEY',
  );
  final FocusNode textFieldFocusNode = FocusNode();
  final SignatureController signatureController = SignatureController(
    penStrokeWidth: 2,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  bool isBluetoothConnected =
      false; // State variable for Bluetooth connection status
  XFile? _imageFile; // State variable for the captured image

  final ImagePicker _picker = ImagePicker(); // ImagePicker instance

  BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
  List<BluetoothDevice> devices = [];
  BluetoothDevice? selectedDevice;
  bool isConnected = false;

  final DatabaseHelper _dbHelper = DatabaseHelper();
  String memberName = "No member found";

  String? get name => null;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    textFieldFocusNode.addListener(() {
      if (textFieldFocusNode.hasFocus) {
        textController.clear();
      } else {
        _searchMember();
      }
    });
  }

  Future<void> _checkPermissions() async {
    await Permission.bluetooth.request();
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
  }

  Future<void> _getDevices() async {
    try {
      List<BluetoothDevice> list = await bluetooth.getBondedDevices();
      setState(() {
        devices = list;
      });
    } catch (e) {
      if (kDebugMode) {
        print("Error: $e");
      }
    }
  }

  Future<void> _toggleConnection() async {
    if (isConnected) {
      await bluetooth.disconnect();
      setState(() {
        isConnected = false;
        isBluetoothConnected = false;
      });
    } else {
      if (selectedDevice == null) return;
      try {
        await bluetooth.connect(selectedDevice!);
        setState(() {
          isConnected = true;
          isBluetoothConnected = true;
        });
        Navigator.of(context).pop(); // Close the modal when connected
      } catch (e) {
        if (kDebugMode) {
          print("Error: $e");
        }
      }
    }
  }

  @override
  void dispose() {
    textController.dispose();
    textFieldFocusNode.dispose();
    signatureController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
    );

    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
      });

      // Log the picked image path
      if (kDebugMode) {
        print('Picked image path: ${_imageFile!.path}');
      }
    } else {
      if (kDebugMode) {
        print('No image was picked.');
      }
    }
  }

  void _resetCamera() {
    setState(() {
      _imageFile = null;
    });
  }

  void _resetSignature() {
    signatureController.clear();
  }

  Future<void> _saveInfo() async {
  if (textController.text.isEmpty || textController.text == 'ENTER CIF KEY') {
    _showAlertDialog('Error', 'Please input the CIF KEY.');
    return;
  }

  if (_imageFile == null) {
    _showAlertDialog('Error', 'Please capture an image.');
    if (kDebugMode) {
      print('Error: _imageFile is null');
    }
    return;
  }

  if (signatureController.isEmpty) {
    _showAlertDialog('Error', 'Please provide a signature.');
    if (kDebugMode) {
      print('Error: signatureController is empty');
    }
    return;
  }

  try {
    final signatureBytes = await signatureController.toPngBytes();
    final dataToSave = {
      'name': memberName,
      'imagePath': _imageFile?.path,
      'signature': signatureBytes,
    };

    // Check if the member exists
    Map<String, dynamic>? existingMember = await _dbHelper.getMemberByCIFKey(textController.text);

    if (existingMember == null) {
      // Insert new member if not found
      await _dbHelper.insertMember({
        'cifkey': textController.text,
        ...dataToSave,
      });
      _showAlertDialog('Success', 'Member information saved successfully.');
    } else {
      // Update existing member's data
      await _dbHelper.updateMember(textController.text, dataToSave);
      _showAlertDialog('Success', 'Member information updated successfully.');
    }

    // Clear all displayed data
    setState(() {
      textController.text = 'ENTER CIF KEY';
      memberName = "No member found";
      _imageFile = null;
      signatureController.clear();
    });
  } catch (e) {
    _showAlertDialog('Error', 'Failed to save the information.');
    if (kDebugMode) {
      print('Error saving data: $e');
    }
  }
}

  Future<void> _searchMember() async {
  String cifKey = textController.text;

  // Fetch the member from the database using the CIF Key
  Map<String, dynamic>? member = await _dbHelper.getMemberByCIFKey(cifKey);

  if (member != null) {
    setState(() {
      // Update the member name
      memberName = member["name"] ?? "No Name";

      // Check if the image path exists and is valid
      if (member["imagePath"] != null && File(member["imagePath"]).existsSync()) {
        _imageFile = XFile(member["imagePath"]);
      } else {
        _imageFile = null; // Reset the image if the path is invalid
        if (kDebugMode) {
          print('Image file does not exist at path: ${member["imagePath"]}');
        }
      }

      // Do not display the signature in the UI
      signatureController.clear();
    });

    if (kDebugMode) {
      print('Retrieved member data: $member');
    }
  } else {
    // If no member is found, reset the display
    setState(() {
      memberName = "No member found";
      _imageFile = null;
      signatureController.clear();
    });

    if (kDebugMode) {
      print('No member found with CIF Key: $cifKey');
    }
  }
}

  void _showAlertDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _Ticket() async {
    final bluetooth = await getBluetoothInstance();
    bluetooth.isConnected.then((isConnected) {
      if (isConnected!) {
        bluetooth.printCustom("Raffle Ticket!", 2, 1);
        bluetooth.printNewLine();
        bluetooth.paperCut();
      } else {
        if (kDebugMode) {
          print("Bluetooth is not connected");
        }
      }
    });
  }

  Future<void> _meal() async {
    final bluetooth = await getBluetoothInstance();
    bluetooth.isConnected.then((isConnected) {
      if (isConnected!) {
        bluetooth.printCustom("Meal Coupon!", 2, 1);
        bluetooth.printNewLine();
        bluetooth.paperCut();
      } else {
        if (kDebugMode) {
          print("Bluetooth is not connected");
        }
      }
    });
  }

  Future<void> _attendance() async {
    final bluetooth = await getBluetoothInstance();
    bluetooth.isConnected.then((isConnected) {
      if (isConnected!) {
        bluetooth.printCustom("Attendance Slip!", 2, 1);
        bluetooth.printNewLine();
        bluetooth.paperCut();
      } else {
        if (kDebugMode) {
          print("Bluetooth is not connected");
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Color(0xFFEEEE15),
        appBar: AppBar(
          backgroundColor: Color(0xFFE3E922),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: Icon(
                Icons.bluetooth_sharp,
                color: isBluetoothConnected ? Colors.green : Colors.white,
              ),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('Bluetooth'),
                      content: Container(
                        width: double.maxFinite,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ElevatedButton(
                              onPressed: _getDevices,
                              child: const Text("Search Devices"),
                            ),
                            Text("Devices: ${devices.length}"),
                            DropdownButton<BluetoothDevice>(
                              hint: const Text("Select Printer"),
                              value: selectedDevice,
                              onChanged: (BluetoothDevice? device) {
                                setState(() {
                                  selectedDevice = device;
                                });
                              },
                              items:
                                  devices
                                      .map(
                                        (device) => DropdownMenuItem(
                                          value: device,
                                          child: Text(device.name!),
                                        ),
                                      )
                                      .toList(),
                            ),
                            Text("Selected: ${selectedDevice?.name ?? "None"}"),
                            ElevatedButton(
                              onPressed: _toggleConnection,
                              child: Text(
                                isConnected ? "Disconnect" : "Connect",
                              ),
                            ),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text('Close'),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
          elevation: 2,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFFF3165),
                    Color(0xFFEFFE52),
                    Color(0xFFFAEE0A),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: screenHeight * 0.05),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(
                      width: screenWidth * 0.8,
                      child: TextFormField(
                        controller: textController,
                        focusNode: textFieldFocusNode,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onFieldSubmitted: (value) {
                          _searchMember();
                        },
                      ),
                    ),
                    Column(
                      children: [
                        // Display Member Name
                        Text(
                          memberName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Display Captured Image or Placeholder
                        CircleAvatar(
                          radius: screenWidth * 0.2,
                          backgroundImage:
                              _imageFile != null
                                  ? FileImage(
                                    File(_imageFile!.path),
                                  ) // Display the image if available
                                  : null,
                          child:
                              _imageFile == null
                                  ? const Icon(
                                    Icons.person,
                                    size: 50,
                                    color: Colors.grey,
                                  ) // Display a placeholder if no image is available
                                  : null,
                        ),
                        const SizedBox(height: 8),

                        // Display message if no image is available
                        if (_imageFile == null)
                          const Text(
                            'Please capture the image',
                            style: TextStyle(color: Colors.red, fontSize: 14),
                          ),
                      ],
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: _pickImage,
                          child: Text('Camera'),
                        ),
                        SizedBox(width: screenWidth * 0.02),
                        ElevatedButton(
                          onPressed: _resetCamera,
                          child: Text('Reset Camera'),
                        ),
                      ],
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    Signature(
                      controller: signatureController,
                      backgroundColor: Colors.white,
                      width: screenWidth * 0.8,
                      height: screenHeight * 0.2,
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: _resetSignature,
                          child: Text('Reset Signature'),
                        ),
                        SizedBox(width: screenWidth * 0.02),
                        ElevatedButton(
                          onPressed: _saveInfo,
                          child: Text('Save Info'),
                        ),
                      ],
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        GestureDetector(
                          onTap: _Ticket,
                          child: _buildOptionCard(
                            'Raffle Ticket',
                            FontAwesomeIcons.ticketAlt,
                            Colors.red,
                          ),
                        ),
                        GestureDetector(
                          onTap: _meal,
                          child: _buildOptionCard(
                            'Meal Coupon',
                            Icons.set_meal,
                            Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    GestureDetector(
                      onTap: _attendance,
                      child: _buildOptionCard(
                        'Attendance Slip',
                        FontAwesomeIcons.calendar,
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard(String title, IconData icon, Color color) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
      width: screenWidth * 0.4,
      height: screenWidth * 0.3,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.8), color.withOpacity(0.5)],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: screenWidth * 0.05,
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(icon: Icon(icon, color: Colors.white), onPressed: () {}),
        ],
      ),
    );
  }

  Future<BlueThermalPrinter> getBluetoothInstance() async {
    return BlueThermalPrinter.instance;
  }

  generateDataToSave(
    String text,
    String memberName,
    String path,
    Uint8List? signatureBytes,
  ) {}
}

extension on SignatureController {
  void importData(Uint8List uint8list) {}
}
