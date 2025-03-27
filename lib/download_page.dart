import 'package:agmm_v3/HomePage.dart';
import 'package:agmm_v3/reg_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'database_helper.dart';

class DownloadPage extends StatefulWidget {
  const DownloadPage({super.key});

  @override
  State<DownloadPage> createState() => _DownloadPageState();
}

class _DownloadPageState extends State<DownloadPage> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  String cifkey = "Loading";
  String name = "Loading";

  void _showAddModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String? selectedMunicipality;
        String? selectedBarangay;

        List<String> municipalities = [
          'Jagna',
          'Getafe',
          'Buenavista',
          'Inabanga',
          'San Miguel',
          'Guindulman',
          'Ubay',
        ];
        municipalities.sort();

        Map<String, List<String>> barangays = {
          'Jagna': ['Bunga-ilaya', 'tejero', 'can uba', 'Malbog', 'Cantagay', 'Buyog'],
          'Getafe': ['buyog', 'Santono', 'San Jose'],
          'Buenavista': ['jonel', 'jay', 'jayson'],
          'Inabanga': ['jonel', 'jay', 'jayson'],
          'San Miguel': ['jonel', 'jay', 'jayson'],
          'Ubay': ['polacion'],
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
                    if (selectedMunicipality != null && selectedBarangay != null) {
                      print('Selected Municipality: $selectedMunicipality');
                      print('Selected Barangay: $selectedBarangay');
                      _showLoadingDialog(context);
                      await _fetchData(selectedMunicipality!, selectedBarangay!);
                      Navigator.of(context).pop(); // Close the loading dialog
                      _showDownloadedDialog(context);
                    }
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

  Future<void> _fetchData(String municipality, String barangay) async {
    try {
      final response = await http.post(
        Uri.parse("http://192.168.1.214:3000/api/members/address"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"municipality": municipality, "barangay": barangay}),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        // Print the entire response body for debugging
        print('Response body: ${response.body}');
        // Print the first element of the data list
        print('First element: ${data[0]}');

        setState(() {
          cifkey = data[0]["CIFKey"];
          name = data[0]["MemberName"];
        });

        // Save data to SQLite
        for (var item in data) {
          Map<String, dynamic>? existingMember = await _dbHelper.getMemberByCIFKey(item["CIFKey"]);
          if (existingMember == null) {
            await _dbHelper.insertMember({
              "cifkey": item["CIFKey"],
              "name": item["MemberName"],
            });
          } else {
            print('Member with CIFKey ${item["CIFKey"]} is already registered.');
          }
        }

        // Print all elements of the data list
        for (var item in data) {
          print('CIFKey: ${item["CIFKey"]}, MemberName: ${item["MemberName"]}');
        }
      } else {
        // Print the status code and response body for debugging
        print('Failed to load data. Status code: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      // Print the error message for debugging
      print('Error: $e');
    }
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

  Future<void> _showMembers() async {
    List<Map<String, dynamic>> members = await _dbHelper.getMembers();
    for (var member in members) {
      print('CIFKey: ${member["cifkey"]}, Name: ${member["name"]}');
    }
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
                        ElevatedButton.icon(
                          onPressed: () {
                            _showMembers();
                          },
                          icon: const Icon(Icons.list, size: 15),
                          label: const Text('Show Members'),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.05,
                              vertical: screenHeight * 0.02,
                            ),
                            backgroundColor: Colors.green, // Adjust color as needed
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