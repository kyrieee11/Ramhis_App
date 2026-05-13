import 'package:flutter/material.dart';

import 'package:ramhis_app/models/event_model.dart';
import 'package:ramhis_app/services/api/event_service.dart';

class AdminEventsScreen extends StatefulWidget {
  const AdminEventsScreen({super.key});

  @override
  State<AdminEventsScreen> createState() => _AdminEventsScreenState();
}

class _AdminEventsScreenState extends State<AdminEventsScreen> {
  bool isLoading = true;
  bool isSaving = false;

  List<EventModel> events = [];

  @override
  void initState() {
    super.initState();
    fetchEvents();
  }

  Future<void> fetchEvents() async {
    setState(() => isLoading = true);

    try {
      final result = await EventService.adminGetEvents();

      if (!mounted) return;

      setState(() {
        events = result;
      });
    } catch (error) {
      _showSnackBar(
        error.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _saveEvent({
    EventModel? existingEvent,
    required String title,
    required String description,
    required String location,
    required String operationDays,
    required String callTime,
    required String meetingPlace,
    required DateTime? missionDate,
  }) async {
    setState(() => isSaving = true);

    try {
      if (existingEvent == null) {
        await EventService.adminCreateEvent(
          title: title,
          description: description,
          location: location,
          operationDays: operationDays,
          callTime: callTime,
          meetingPlace: meetingPlace,
          missionDate: missionDate,
        );

        _showSnackBar('Event created successfully.');
      } else {
        await EventService.adminUpdateEvent(
          eventId: existingEvent.id,
          title: title,
          description: description,
          location: location,
          operationDays: operationDays,
          callTime: callTime,
          meetingPlace: meetingPlace,
          missionDate: missionDate,
        );

        _showSnackBar('Event updated successfully.');
      }

      await fetchEvents();
    } catch (error) {
      _showSnackBar(
        error.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  Future<void> _deleteEvent(String eventId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Event'),
        content: const Text('Are you sure you want to delete this event?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => isSaving = true);

    try {
      await EventService.adminDeleteEvent(eventId);

      _showSnackBar('Event deleted successfully.');
      await fetchEvents();
    } catch (error) {
      _showSnackBar(
        error.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  void _showEventForm({EventModel? event}) {
    final titleController = TextEditingController(text: event?.title ?? '');
    final descriptionController =
        TextEditingController(text: event?.description ?? '');
    final locationController =
        TextEditingController(text: event?.location ?? '');
    final operationDaysController =
        TextEditingController(text: event?.operationDays ?? '');
    final callTimeController =
        TextEditingController(text: event?.callTime ?? '');
    final meetingPlaceController =
        TextEditingController(text: event?.meetingPlace ?? '');

    DateTime? selectedDate = event?.missionDate != null
    ? DateTime.tryParse(event!.missionDate)
    : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF6F8FC),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> pickDate() async {
              final now = DateTime.now();

              final picked = await showDatePicker(
                context: context,
                initialDate: selectedDate ?? now,
                firstDate: DateTime(now.year - 1),
                lastDate: DateTime(now.year + 5),
              );

              if (picked == null) return;

              setSheetState(() {
                selectedDate = picked;
              });
            }

            Future<void> submit() async {
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

              Navigator.pop(sheetContext);

              await _saveEvent(
                existingEvent: event,
                title: title,
                description: description,
                location: location,
                operationDays: operationDays,
                callTime: callTime,
                meetingPlace: meetingPlace,
                missionDate: selectedDate,
              );
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 18,
                right: 18,
                top: 18,
                bottom: MediaQuery.of(context).viewInsets.bottom + 18,
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      event == null ? 'Create Event' : 'Edit Event',
                      style: const TextStyle(
                        color: Color(0xFF172B5F),
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _input(
                      controller: titleController,
                      label: 'Title',
                      icon: Icons.event_outlined,
                    ),
                    const SizedBox(height: 12),
                    _input(
                      controller: descriptionController,
                      label: 'Description',
                      icon: Icons.description_outlined,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    _input(
                      controller: locationController,
                      label: 'Location',
                      icon: Icons.location_on_outlined,
                    ),
                    const SizedBox(height: 12),
                    _input(
                      controller: operationDaysController,
                      label: 'Operation Days',
                      icon: Icons.calendar_view_week_outlined,
                    ),
                    const SizedBox(height: 12),
                    _input(
                      controller: callTimeController,
                      label: 'Call Time',
                      icon: Icons.access_time_outlined,
                    ),
                    const SizedBox(height: 12),
                    _input(
                      controller: meetingPlaceController,
                      label: 'Meeting Place',
                      icon: Icons.groups_outlined,
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: pickDate,
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.date_range_outlined,
                              color: Color(0xFF4169D8),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                selectedDate == null
                                    ? 'Select Mission Date'
                                    : _formatDate(selectedDate!),
                                style: TextStyle(
                                  color: selectedDate == null
                                      ? Colors.grey
                                      : const Color(0xFF172B5F),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: isSaving ? null : submit,
                        icon: const Icon(Icons.save_outlined),
                        label: Text(event == null ? 'Create' : 'Update'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD95362),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      titleController.dispose();
      descriptionController.dispose();
      locationController.dispose();
      operationDaysController.dispose();
      callTimeController.dispose();
      meetingPlaceController.dispose();
    });
  }

  Widget _input({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          icon,
          color: const Color(0xFF4169D8),
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  void _showSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'done':
        return Colors.grey;
      case 'ongoing':
        return Colors.green;
      case 'upcoming':
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        title: const Text('Admin Events'),
        backgroundColor: const Color(0xFF4169D8),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: isSaving ? null : () => _showEventForm(),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchEvents,
              child: events.isEmpty
                  ? const Center(
                      child: Text(
                        'No events found.',
                        style: TextStyle(
                          color: Color(0xFF172B5F),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: events.length,
                      itemBuilder: (context, index) {
                        final event = events[index];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 14),
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const CircleAvatar(
                                      backgroundColor: Color(0xFF4169D8),
                                      child: Icon(
                                        Icons.event_outlined,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        event.title,
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF172B5F),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _statusColor(
                                          event.status,
                                        ).withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        event.status,
                                        style: TextStyle(
                                          color: _statusColor(event.status),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if (event.description.isNotEmpty)
                                  Text(event.description),
                                const SizedBox(height: 10),
                                if (event.location.isNotEmpty)
                                  Text('Location: ${event.location}'),
                                if (event.operationDays.isNotEmpty)
                                  Text(
                                    'Operation Days: ${event.operationDays}',
                                  ),
                                if (event.callTime.isNotEmpty)
                                  Text('Call Time: ${event.callTime}'),
                                if (event.meetingPlace.isNotEmpty)
                                  Text(
                                    'Meeting Place: ${event.meetingPlace}',
                                  ),
                               
                                  Text(
                                    'Mission Date: ${_formatDate(DateTime.parse(event.missionDate))}',
                                  ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: isSaving
                                            ? null
                                            : () =>
                                                _showEventForm(event: event),
                                        icon: const Icon(Icons.edit_outlined),
                                        label: const Text('Edit'),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: isSaving
                                            ? null
                                            : () => _deleteEvent(event.id),
                                        icon: const Icon(Icons.delete_outline),
                                        label: const Text('Delete'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}