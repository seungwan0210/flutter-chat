import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'diamond_management_tab.dart'; // 다이아 관리 탭
import 'account_management_tab.dart'; // 계정 관리 탭

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("어드민 페이지", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.amber,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.amber,
          tabs: const [
            Tab(text: "다이아 관리"),
            Tab(text: "계정 관리"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          DiamondManagementTab(),
          AccountManagementTab(),
        ],
      ),
    );
  }
}