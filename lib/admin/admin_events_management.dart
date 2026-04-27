import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/auth_token_session_flow.dart';

class AdminEventsManagementConnectedWidget extends StatefulWidget {
  const AdminEventsManagementConnectedWidget({super.key});

  @override
  State<AdminEventsManagementConnectedWidget> createState() =>
      _AdminEventsManagementConnectedWidgetState();
}

class _AdminEventsManagementConnectedWidgetState
    extends State<AdminEventsManagementConnectedWidget> {
  bool isLoading = true;
  bool isSubmitting = false;

  List<Map<String, dynamic>> events = [];

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final locationController = TextEditingController();
  final operationDaysController = TextEditingController();
  final callTimeController = TextEditingController();
  final meetingPlaceController = TextEditingController();

  DateTime? missionDate;
  String? editingEventId;

  @override
  void initState() {
    super.initState();
    fetchEvents();
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    locationController.dispose();
    operationDaysController.dispose();
    callTimeController.dispose();
    meetingPlaceController.dispose();
    super.dispose();
  }

  Future<void> fetchEvents() async {
    if (mounted) setState(() => isLoading = true);

    try {
      final response = await AuthApi.get('/admin/events');

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          events = List<Map<String, dynamic>>.from(data);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        final data = AuthApi.tryDecodeMap(response.body);
        _showSnackBar(
          (data?['message'] ?? 'Failed to load events.').toString(),
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => isLoading = false);
      _showSnackBar('Connection error.');
    }
  }

  void _clearForm() {
    editingEventId = null;
    missionDate = null;
    titleController.clear();
    descriptionController.clear();
    locationController.clear();
    operationDaysController.clear();
    callTimeController.clear();
    meetingPlaceController.clear();
  }

  void _fillForm(Map<String, dynamic> event) {
    editingEventId = (event['_id'] ?? '').toString();
    titleController.text = (event['title'] ?? '').toString();
    descriptionController.text = (event['description'] ?? '').toString();
    locationController.text = (event['location'] ?? '').toString();
    operationDaysController.text = (event['operation_days'] ?? '').toString();
    callTimeController.text = (event['call_time'] ?? '').toString();
    meetingPlaceController.text = (event['meeting_place'] ?? '').toString();

    final rawMissionDate = event['mission_date'];
    missionDate = rawMissionDate != null
        ? DateTime.tryParse(rawMissionDate.toString())
        : null;
  }

  Future<void> _pickMissionDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: missionDate ?? now,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(2035),
    );

    if (picked == null) return;

    missionDate = picked;

    setState(() {
      operationDaysController.text = DateFormat('MMM dd, yyyy').format(picked);
    });
  }

  Future<void> _pickCallTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (selected == null) return;

    final now = DateTime.now();
    final dateTime = DateTime(
      now.year,
      now.month,
      now.day,
      selected.hour,
      selected.minute,
    );

    setState(() {
      callTimeController.text = DateFormat('hh:mm a').format(dateTime);
    });
  }

  Future<void> createEvent() async {
    final title = titleController.text.trim();
    final description = descriptionController.text.trim();
    final location = locationController.text.trim();
    final operationDays = operationDaysController.text.trim();
    final callTime = callTimeController.text.trim();
    final meetingPlace = meetingPlaceController.text.trim();

    if (title.isEmpty || location.isEmpty) {
      _showSnackBar('Title and location are required.');
      return;
    }

    if (missionDate == null) {
      _showSnackBar('Please select a mission date.');
      return;
    }

    if (callTime.isEmpty) {
      _showSnackBar('Please select a call time.');
      return;
    }

    if (mounted) setState(() => isSubmitting = true);

    try {
      final response = await AuthApi.post(
        '/admin/events',
        body: {
          'title': title,
          'description': description,
          'location': location,
          'operation_days': operationDays,
          'call_time': callTime,
          'meeting_place': meetingPlace,
          'mission_date': missionDate!.toIso8601String(),
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        Navigator.pop(context);
        _clearForm();
        await fetchEvents();
        _showSnackBar('Event created successfully.');
      } else {
        final data = AuthApi.tryDecodeMap(response.body);
        _showSnackBar(
          (data?['message'] ?? 'Failed to create event.').toString(),
        );
      }
    } catch (_) {
      _showSnackBar('Connection error.');
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  Future<void> updateEvent() async {
    final eventId = editingEventId;
    final title = titleController.text.trim();
    final description = descriptionController.text.trim();
    final location = locationController.text.trim();
    final operationDays = operationDaysController.text.trim();
    final callTime = callTimeController.text.trim();
    final meetingPlace = meetingPlaceController.text.trim();

    if (eventId == null || eventId.isEmpty) {
      _showSnackBar('Invalid event selected.');
      return;
    }

    if (title.isEmpty || location.isEmpty) {
      _showSnackBar('Title and location are required.');
      return;
    }

    if (missionDate == null) {
      _showSnackBar('Please select a mission date.');
      return;
    }

    if (callTime.isEmpty) {
      _showSnackBar('Please select a call time.');
      return;
    }

    if (mounted) setState(() => isSubmitting = true);

    try {
      final response = await AuthApi.put(
        '/admin/events/$eventId',
        body: {
          'title': title,
          'description': description,
          'location': location,
          'operation_days': operationDays,
          'call_time': callTime,
          'meeting_place': meetingPlace,
          'mission_date': missionDate!.toIso8601String(),
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        Navigator.pop(context);
        _clearForm();
        await fetchEvents();
        _showSnackBar('Event updated successfully.');
      } else {
        final data = AuthApi.tryDecodeMap(response.body);
        _showSnackBar(
          (data?['message'] ?? 'Failed to update event.').toString(),
        );
      }
    } catch (_) {
      _showSnackBar('Connection error.');
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  Future<void> deleteEvent(String eventId) async {
    try {
      final response = await AuthApi.post(
        '/admin/events/delete',
        body: {'eventId': eventId},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        await fetchEvents();
        _showSnackBar('Event deleted successfully.');
      } else {
        final data = AuthApi.tryDecodeMap(response.body);
        _showSnackBar(
          (data?['message'] ?? 'Failed to delete event.').toString(),
        );
      }
    } catch (_) {
      _showSnackBar('Connection error.');
    }
  }

  Future<void> confirmDelete(String eventId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_rounded,
                color: Colors.red,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Delete Event?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This action cannot be undone.\nAre you sure you want to delete this event?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF667085),
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD95362),
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await deleteEvent(eventId);
    }
  }

  void openCreateDialog() {
    _clearForm();
    _openEventDialog(isEdit: false);
  }

  void openEditDialog(Map<String, dynamic> event) {
    _fillForm(event);
    _openEventDialog(isEdit: true);
  }

  Widget _statusChip(Map<String, dynamic> event) {
    final status = (event['status'] ?? 'Upcoming').toString();
    Color color;

    switch (status.toLowerCase()) {
      case 'ongoing':
        color = Colors.orange;
        break;
      case 'done':
        color = Colors.grey;
        break;
      default:
        color = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }

  void _openEventDialog({required bool isEdit}) {
    showDialog(
      context: context,
      barrierDismissible: !isSubmitting,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(isEdit ? 'Edit Event' : 'Create Event'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(labelText: 'Location'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: operationDaysController,
                readOnly: true,
                onTap: _pickMissionDate,
                decoration: const InputDecoration(
                  labelText: 'Mission Date',
                  hintText: 'Select mission date',
                  suffixIcon: Icon(Icons.calendar_today_rounded),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: callTimeController,
                readOnly: true,
                onTap: _pickCallTime,
                decoration: const InputDecoration(
                  labelText: 'Call Time',
                  hintText: 'Select time',
                  suffixIcon: Icon(Icons.access_time_rounded),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: meetingPlaceController,
                decoration: const InputDecoration(
                  labelText: 'Meeting Place',
                  hintText: '#2218 Baker St.',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: isSubmitting ? null : () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: isSubmitting ? null : (isEdit ? updateEvent : createEvent),
            child: isSubmitting
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(isEdit ? 'Save' : 'Create'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _eventSubtitle(Map<String, dynamic> event) {
    final location = (event['location'] ?? '').toString();
    final missionDate = (event['operation_days'] ?? '').toString();
    final callTime = (event['call_time'] ?? '').toString();

    final parts = <String>[
      if (location.isNotEmpty) location,
      if (missionDate.isNotEmpty) missionDate,
      if (callTime.isNotEmpty) callTime,
    ];

    return parts.isEmpty ? 'No extra details' : parts.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Events Management'),
        actions: [
          IconButton(
            onPressed: fetchEvents,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: openCreateDialog,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : events.isEmpty
              ? const Center(child: Text('No events found.'))
              : ListView.builder(
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    final volunteers =
                        (event['volunteers'] as List?)?.length ?? 0;
                    final eventId = (event['_id'] ?? '').toString();

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: ListTile(
                        title: Row(
                          children: [
                            Expanded(
                              child: Text((event['title'] ?? '').toString()),
                            ),
                            _statusChip(event),
                          ],
                        ),
                        subtitle: Text(_eventSubtitle(event)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.people_alt_outlined, size: 18),
                                const SizedBox(height: 2),
                                Text('$volunteers'),
                              ],
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              tooltip: 'Edit',
                              icon: const Icon(
                                Icons.edit_outlined,
                                color: Colors.blue,
                              ),
                              onPressed: () => openEditDialog(event),
                            ),
                            IconButton(
                              tooltip: 'Delete',
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              onPressed: eventId.isEmpty
                                  ? null
                                  : () => confirmDelete(eventId),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: openCreateDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}