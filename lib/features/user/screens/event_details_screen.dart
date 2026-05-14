import 'package:flutter/material.dart';
import 'package:ramhis_app/services/api/event_service.dart';

class EventDetailsWidget extends StatefulWidget {
  const EventDetailsWidget({
    super.key,
    required this.eventId,
  });

  final String eventId;

  @override
  State<EventDetailsWidget> createState() =>
      _EventDetailsWidgetState();
}

class _EventDetailsWidgetState
    extends State<EventDetailsWidget> {
  bool isLoading = true;

  List<Map<String, dynamic>> participants = [];

  @override
  void initState() {
    super.initState();
    _loadParticipants();
  }

  Future<void> _loadParticipants() async {
    if (!mounted) return;

    setState(() => isLoading = true);

    try {
      final data = await EventService.getParticipants(
        widget.eventId,
      );

      participants = data
          .map(
            (item) => Map<String, dynamic>.from(item),
          )
          .toList();
    } catch (error) {
      debugPrint(
        '❌ Failed to load participants: $error',
      );

      participants = [];
    }

    if (!mounted) return;

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF3E5EBE),

      appBar: AppBar(
        backgroundColor: const Color(0xFF4766C7),

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),

        title: const Text(
          'Volunteers',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            )
          : participants.isEmpty
              ? const Center(
                  child: Text(
                    'No volunteers yet.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadParticipants,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: participants.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 12),

                    itemBuilder: (context, index) {
                      final participant =
                          participants[index];

                      final String fullName =
                          (participant['full_name'] ??
                                  'Volunteer')
                              .toString();

                      final String email =
                          (participant['email'] ?? '')
                              .toString();

                      final String role =
                          (participant['account_type'] ??
                                  'Volunteer')
                              .toString();

                      return Container(
                        padding: const EdgeInsets.all(14),

                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                              BorderRadius.circular(18),

                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withValues(alpha: 0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),

                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,

                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFE7F0FF,
                                ),
                                borderRadius:
                                    BorderRadius.circular(
                                  16,
                                ),
                              ),

                              child: const Icon(
                                Icons.person_rounded,
                                color: Color(0xFF4766C7),
                                size: 28,
                              ),
                            ),

                            const SizedBox(width: 14),

                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,

                                children: [
                                  Text(
                                    fullName,

                                    maxLines: 1,
                                    overflow:
                                        TextOverflow
                                            .ellipsis,

                                    style:
                                        const TextStyle(
                                      fontSize: 16,
                                      fontWeight:
                                          FontWeight.w700,
                                      color: Color(
                                        0xFF111827,
                                      ),
                                    ),
                                  ),

                                  if (email.isNotEmpty) ...[
                                    const SizedBox(
                                      height: 4,
                                    ),

                                    Text(
                                      email,

                                      maxLines: 1,
                                      overflow:
                                          TextOverflow
                                              .ellipsis,

                                      style:
                                          const TextStyle(
                                        fontSize: 13,
                                        color: Color(
                                          0xFF6B7280,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            const SizedBox(width: 10),

                            Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),

                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFE8EEFF,
                                ),

                                borderRadius:
                                    BorderRadius.circular(
                                  14,
                                ),
                              ),

                              child: Text(
                                role,

                                style: const TextStyle(
                                  color:
                                      Color(0xFF4766C7),
                                  fontWeight:
                                      FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}