import 'package:agmm_v3/HomePage.dart';
import 'package:agmm_v3/reg_page.dart';
import 'package:flutter/material.dart';


class DownloadPage extends StatefulWidget {
  const DownloadPage({super.key});

  @override
  State<DownloadPage> createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  void _showAddModal(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      String? selectedMunicipality;
      String? selectedBarangay;

      List<String> municipalities = [
        'Municipality 1',
        'Municipality 2',
        'Municipality 3'
      ];
      municipalities.sort();

      Map<String, List<String>> barangays = {
        'Municipality 1': ['ilaya', 'mar', 'looc'],
        'Municipality 2': ['miguel', 'hernandez', 'john'],
        'Municipality 3': ['jonel', 'jay', 'jayson'],
      };

      return StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return AlertDialog(
            title: const Text('ADD BARANGAY'),
            content: SingleChildScrollView(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.8, // Adjust the width as needed
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Municipality',
                        border: OutlineInputBorder(),
                      ),
                      items: municipalities.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          selectedMunicipality = newValue;
                          selectedBarangay = null; // Reset barangay selection
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Barangay',
                        border: OutlineInputBorder(),
                      ),
                      items: selectedMunicipality == null
                          ? []
                          : barangays[selectedMunicipality]!.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                      onChanged: selectedMunicipality == null
                          ? null
                          : (newValue) {
                              setState(() {
                                selectedBarangay = newValue;
                              });
                            },
                      value: selectedBarangay,
                      disabledHint: const Text('Select a municipality first'),
                    ),
                  ],
                ),
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text('Add'),
                onPressed: () async {
                  _showLoadingDialog(context);
                  await Future.delayed(const Duration(seconds: 5), () {
                    _showDownloadedDialog(context);
                  }); // Simulate a 5-second download
                },
              ),
            ],
          );
        },
      );
    },
  );
}

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: const [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Downloading...'),
            ],
          ),
        );
      },
    );
  }

  void _showDownloadedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Downloaded'),
          content: const Text('The data has been successfully downloaded.'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const RegPageWidget()),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _showDeleteModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('DELETE BARANGAY'),
          content: const Text('Are you sure you want to delete this barangay?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Delete'),
              onPressed: () {
                // Add your delete item logic here
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: Colors.white, // Replace with your desired color
        appBar: AppBar(
          backgroundColor: Colors.grey[200], // Replace with your theme color
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HomePageWidget()),
              );
            },
          ),
          elevation: 2,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Container(
              width: double.infinity,
              height: screenHeight,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFEF8E39), Color(0xFFE8EA1A)],
                  stops: [0, 1],
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.only(top: screenHeight * 0.1),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            _showAddModal(context);
                          },
                          icon: const Icon(Icons.add_box, size: 15),
                          label: const Text('Add'),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.05,
                              vertical: screenHeight * 0.02,
                            ),
                            backgroundColor: Colors.blue, // Adjust color as needed
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            _showDeleteModal(context);
                          },
                          icon: const Icon(Icons.delete, size: 15),
                          label: const Text('Delete'),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.05,
                              vertical: screenHeight * 0.02,
                            ),
                            backgroundColor: Colors.red, // Adjust color as needed
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
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
}