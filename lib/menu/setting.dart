import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:parking1/loginandregis/loginPage.dart';
import 'package:parking1/main.dart';
import 'package:parking1/menu/Help.dart';
import 'package:parking1/menu/changepass.dart';
import 'package:parking1/menu/editprofile.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeModeOption { system, light, dark }

enum LanguageOption { english, lao }

class SettingPage extends StatefulWidget {
  const SettingPage({Key? key}) : super(key: key);

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  bool _notificationsEnabled = true;
  ThemeModeOption _selectedThemeMode = ThemeModeOption.system;
  LanguageOption _selectedLanguage = LanguageOption.english;
  final auth = FirebaseAuth.instance;
  final String cloudinaryUrl =
      "https://api.cloudinary.com/v1_1/doiq3nkso/image/upload";
  final String uploadPreset = "parking";
  File? _selectedImage;
  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _loadThemeMode();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedLanguage = LanguageOption.values[prefs.getInt('language') ?? 0];
    });

    // ตั้งค่า locale ตามที่โหลด
    if (_selectedLanguage == LanguageOption.english) {
      context.setLocale(const Locale('en'));
    } else if (_selectedLanguage == LanguageOption.lao) {
      context.setLocale(const Locale('lo'));
    }
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedThemeMode =
          ThemeModeOption.values[prefs.getInt('themeMode') ?? 0];
    });
  }

  Future<void> _saveThemeMode(ThemeModeOption themeMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', themeMode.index);

    // Immediately update the app's theme using the global notifier.
    switch (themeMode) {
      case ThemeModeOption.light:
        themeModeNotifier.value = ThemeMode.light;
        break;
      case ThemeModeOption.dark:
        themeModeNotifier.value = ThemeMode.dark;
        break;
      default:
        themeModeNotifier.value = ThemeMode.system;
        break;
    }
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications', _notificationsEnabled);
    await prefs.setInt('themeMode', _selectedThemeMode.index);
    await prefs.setInt('language', _selectedLanguage.index);
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile =
          await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        if (kIsWeb) {
          final Uint8List bytes = await pickedFile.readAsBytes();
          setState(() {
            _imageBytes = bytes;
          });
        } else {
          setState(() {
            _selectedImage = File(pickedFile.path);
          });
        }
        await _uploadImageToCloudinary();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No image selected')),
        );
      }
    } catch (e) {
      print("Error selecting image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error selecting image')),
      );
    }
  }

  Future<void> logout() async {
    bool? confirmLogout = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text("Logout Confirmation"),
          content: const Text("Are you sure you want to log out?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Cancel"),
            ),
            TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  "Logout",
                  style: TextStyle(
                    color: Colors.red,
                  ),
                )),
          ],
        );
      },
    );

    if (confirmLogout == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('email');
      await prefs.remove('password');
      await prefs.remove('rememberMe');
      await FirebaseAuth.instance.signOut();

      // Navigate to login page
      if (context.mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const loginPage()),
        );
      }
    }
  }

  Future<void> _uploadImageToCloudinary() async {
    try {
      if (_selectedImage == null && _imageBytes == null) return;
      var request = http.MultipartRequest('POST', Uri.parse(cloudinaryUrl))
        ..fields['upload_preset'] = uploadPreset;
      if (_imageBytes != null) {
        request.files.add(http.MultipartFile.fromBytes('file', _imageBytes!,
            filename: 'profile_image.jpg'));
      } else if (_selectedImage != null) {
        request.files.add(
            await http.MultipartFile.fromPath('file', _selectedImage!.path));
      }
      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await http.Response.fromStream(response);
        final data = jsonDecode(responseData.body);
        final imageUrl = data['secure_url'];
        await FirebaseFirestore.instance
            .collection('users')
            .doc(auth.currentUser?.uid)
            .update({'profileImage': imageUrl});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile image updated successfully!')),
        );
      } else {
        print("Upload failed with status: ${response.statusCode}");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload image')),
        );
      }
    } catch (e) {
      print("Error uploading image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error uploading image')),
      );
    }
  }

  Widget _buildProfileSection() {
    return Center(
      child: GestureDetector(
        onTap: () {
          // Navigate to the Edit Profile page
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditProfilePage(
                currentImage: _selectedImage, // Pass current image here
              ),
            ),
          );
        },
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.white,
              child: ClipOval(
                child: FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(auth.currentUser?.uid)
                      .get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }
                    if (snapshot.hasError ||
                        !snapshot.hasData ||
                        !snapshot.data!.exists) {
                      return Image.asset('assets/images/profile-user.png',
                          fit: BoxFit.cover, width: 120, height: 120);
                    }
                    final data = snapshot.data!.data() as Map<String, dynamic>;
                    final profileImage = data['profileImage'] ??
                        'assets/images/profile-user.png';
                    return Image.network(
                      profileImage,
                      fit: BoxFit.cover,
                      width: 120,
                      height: 120,
                      errorBuilder: (context, error, stackTrace) => Image.asset(
                          'assets/images/profile-user.png',
                          fit: BoxFit.cover,
                          width: 120,
                          height: 120),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: const BoxDecoration(
                    color: Colors.blue, shape: BoxShape.circle),
                child: const Icon(Icons.edit, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? tileColor,
  }) {
    return Card(
      color: tileColor ?? Theme.of(context).cardColor,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? Colors.blueAccent),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  // Define your color here
  final Color _appBarColor = Colors.white; // Adjust to your desired color

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: Theme.of(context)
            .appBarTheme
            .backgroundColor, // Automatically use theme color
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          children: [
            _buildProfileSection(),
            const SizedBox(height: 30),
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // ListTile(
                    //   leading: const Icon(Icons.brightness_6,
                    //       color: Colors.blueAccent),
                    //   title: const Text(
                    //     "Theme Mode",
                    //     style: TextStyle(fontWeight: FontWeight.w600),
                    //   ),
                    //   trailing: DropdownButton<ThemeModeOption>(
                    //     value: _selectedThemeMode,
                    //     onChanged: (ThemeModeOption? newValue) {
                    //       if (newValue != null) {
                    //         setState(() {
                    //           _selectedThemeMode = newValue;
                    //         });
                    //         _saveThemeMode(newValue);
                    //       }
                    //     },
                    //     items: [
                    //       DropdownMenuItem(
                    //         value: ThemeModeOption.system,
                    //         child: Row(
                    //           children: [
                    //             Image.network('assets/icons/system.png',
                    //                 width: 24, height: 24),
                    //             SizedBox(width: 10),
                    //             Text("System"),
                    //           ],
                    //         ),
                    //       ),
                    //       DropdownMenuItem(
                    //         value: ThemeModeOption.light,
                    //         child: Row(
                    //           children: [
                    //             Image.asset('assets/icons/light.png',
                    //                 width: 24, height: 24),
                    //             SizedBox(width: 10),
                    //             Text("Light Mode"),
                    //           ],
                    //         ),
                    //       ),
                    //       DropdownMenuItem(
                    //         value: ThemeModeOption.dark,
                    //         child: Row(
                    //           children: [
                    //             Image.asset('assets/icons/dark.png',
                    //                 width: 24, height: 24),
                    //             SizedBox(width: 10),
                    //             Text("Dark Mode"),
                    //           ],
                    //         ),
                    //       ),
                    //     ],
                    //   ),
                    // ),
                    ListTile(
                      leading: const Icon(Icons.brightness_6,
                          color: Colors.blueAccent),
                      title: const Text(
                        "Theme Mode",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _selectedThemeMode == ThemeModeOption.system
                                ? Icons.settings
                                : _selectedThemeMode == ThemeModeOption.light
                                    ? Icons.light_mode
                                    : Icons.dark_mode,
                            color: _selectedThemeMode == ThemeModeOption.light
                                ? Colors.orange
                                : _selectedThemeMode == ThemeModeOption.dark
                                    ? Colors.black
                                    : Colors.blueAccent,
                          ),
                          SizedBox(width: 10),
                        ],
                      ),
                      onTap: () {
                        setState(() {
                          // Toggle between Light, Dark, and System mode
                          if (_selectedThemeMode == ThemeModeOption.system) {
                            _selectedThemeMode = ThemeModeOption.light;
                          } else if (_selectedThemeMode ==
                              ThemeModeOption.light) {
                            _selectedThemeMode = ThemeModeOption.dark;
                          } else {
                            _selectedThemeMode = ThemeModeOption.system;
                          }
                        });

                        _saveThemeMode(
                            _selectedThemeMode); // Save theme preference
                      },
                    ),

                    const Divider(),
                    SwitchListTile(
                      title: Text("enable_notifications".tr(),
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      activeColor: Colors.blueAccent,
                      value: _notificationsEnabled,
                      onChanged: (bool value) {
                        setState(() {
                          _notificationsEnabled = value;
                        });
                        _savePreferences();
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildSettingsTile(
              icon: Icons.language,
              title: "language".tr(),
              onTap: () async {
                final LanguageOption? selectedLanguage =
                    await showDialog<LanguageOption>(
                  context: context,
                  builder: (BuildContext context) {
                    LanguageOption tempSelected = _selectedLanguage;
                    return AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      title: Row(
                        children: [
                          Icon(Icons.language, color: Colors.blueAccent),
                          const SizedBox(width: 8),
                           Text(
                            "Select Language".tr(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      content: StatefulBuilder(
                        builder: (BuildContext context, StateSetter setState) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              RadioListTile<LanguageOption>(
                                title: Text("english".tr()),
                                value: LanguageOption.english,
                                groupValue: tempSelected,
                                activeColor: Colors.blueAccent,
                                onChanged: (LanguageOption? value) {
                                  setState(() {
                                    tempSelected = value!;
                                  });
                                },
                              ),
                              RadioListTile<LanguageOption>(
                                 title: Text("lao".tr()),
                                value: LanguageOption.lao,
                                groupValue: tempSelected,
                                activeColor: Colors.blueAccent,
                                onChanged: (LanguageOption? value) {
                                  setState(() {
                                    tempSelected = value!;
                                  });
                                },
                              ),
                            ],
                          );
                        },
                      ),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () async {
                            Navigator.pop(context, tempSelected);
                          },
                          child: Text(
                            "ok".tr(),
                            style: TextStyle(
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text(
                            "Cancel".tr(),
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );

                if (selectedLanguage != null) {
                  setState(() {
                    _selectedLanguage = selectedLanguage;
                  });

                  // เปลี่ยนภาษาใน EasyLocalization
                  if (_selectedLanguage == LanguageOption.english) {
                    context.setLocale(const Locale('en'));
                  } else if (_selectedLanguage == LanguageOption.lao) {
                    context.setLocale(const Locale('lo'));
                  }

                  // บันทึกลง SharedPreferences
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setInt('language', _selectedLanguage.index);
                }
              },
            ),
            _buildSettingsTile(
              icon: Icons.help,
              title: "help".tr(),
              onTap: () {
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (c) => Help()));
              },
            ),
            _buildSettingsTile(
              icon: Icons.lock,
              title: "change_password".tr(),
              onTap: () {
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (c) => Changepass()));
              },
            ),
            _buildSettingsTile(
              icon: Icons.info,
              title: "about_app".tr(),
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: "Parking App",
                  applicationVersion: "1.0.0",
                  applicationIcon: const Icon(Icons.local_parking),
                  children: const [Text("This is a parking management app.")],
                );
              },
            ),
            _buildSettingsTile(
              icon: Icons.logout,
              title: "logout".tr(),
              iconColor: Colors.redAccent,
              onTap: () async {
                await logout();
              },
            ),
          ],
        ),
      ),
    );
  }
}
