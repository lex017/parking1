import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:parking1/detailownner/edit_fromEpm.dart';
import 'package:parking1/menu/emp_register.dart';


class EditEmployee extends StatefulWidget {
  final String locationId; // Location ID to filter employees

  const EditEmployee({super.key, required this.locationId});

  @override
  State<EditEmployee> createState() => _EditEmployeeState();
}

class _EditEmployeeState extends State<EditEmployee> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> fetchEmployees() async {
    QuerySnapshot snapshot = await _firestore
        .collection('employees')
        .where('locationId', isEqualTo: widget.locationId)
        .get();

    return snapshot.docs.map((doc) {
      return {
        'id': doc.id,
        ...doc.data() as Map<String, dynamic>,
      };
    }).toList();
  }

  void editEmployee(String employeeId) async {
    DocumentSnapshot snapshot =
        await _firestore.collection('employees').doc(employeeId).get();

    if (snapshot.exists) {
      Map<String, dynamic> employeeData = {
        'id': snapshot.id,
        ...snapshot.data() as Map<String, dynamic>
      };

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EditEmployeeForm(employee: employeeData),
        ),
      ).then((_) => setState(() {})); // Refresh when returning
    }
  }

  void addEmployee() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => emp_register(), // Make sure this param is supported
      ),
    ).then((_) => setState(() {})); // Refresh when returning
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchEmployees(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No employees found for this location.'));
          } else {
            List<Map<String, dynamic>> employees = snapshot.data!;
            return ListView.builder(
              itemCount: employees.length,
              itemBuilder: (context, index) {
                Map<String, dynamic> employee = employees[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: employee['profileImage'] != null &&
                            employee['profileImage'].toString().isNotEmpty
                        ? NetworkImage(employee['profileImage'])
                        : const AssetImage('assets/default_profile.png')
                            as ImageProvider,
                  ),
                  title: Text('${employee['firstname']} ${employee['lastname']}'),
                  subtitle: Text('Emp ID: ${employee['emp_id']}'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        editEmployee(employee['id']);
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: Text('Edit'),
                      ),
                    ],
                  ),
                );
              },
            );
          }
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: addEmployee,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Add Employee',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}
