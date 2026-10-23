import 'package:flutter/material.dart';
import 'customize_elder.dart';
import 'customize_questions.dart';
import 'customize_schedule.dart';

const olive = Color(0xFF343B2D);

class CustomizeScreen extends StatelessWidget {
  const CustomizeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F5EE),
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.transparent,
          title: const Text(
            'Customize Check-in',
            style: TextStyle(fontWeight: FontWeight.bold, color: olive),
          ),
          bottom: const TabBar(
            labelColor: olive,
            unselectedLabelColor: Colors.black54,
            indicatorColor: olive,
            indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            tabs: [
              Tab(
                icon: Icon(Icons.quiz_outlined, size: 20),
                text: 'Questions',
              ),
              Tab(
                icon: Icon(Icons.alarm_outlined, size: 20),
                text: 'Schedule',
              ),
              Tab(
                icon: Icon(Icons.phone_iphone_outlined, size: 20),
                text: 'Phone & Profile',
              ),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            CustomizeQuestionsTab(),
            CustomizeScheduleTab(),
            CustomizeElderTab(),
          ],
        ),
      ),
    );
  }
}