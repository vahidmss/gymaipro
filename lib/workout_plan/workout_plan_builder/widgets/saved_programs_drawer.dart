import 'package:flutter/material.dart';
import '../models/workout_program.dart';
import 'package:lucide_icons/lucide_icons.dart';

class SavedProgramsDrawer extends StatelessWidget {
  final List<WorkoutProgram> savedPrograms;
  final bool isLoading;
  final void Function(String programId) onSelect;
  final VoidCallback onCreateNew;
  final VoidCallback onClose;

  const SavedProgramsDrawer({
    Key? key,
    required this.savedPrograms,
    required this.isLoading,
    required this.onSelect,
    required this.onCreateNew,
    required this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black.withOpacity(0.2),
        child: Align(
          alignment: Alignment.centerRight,
          child: Container(
            width: 320,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF2C1810),
                  Color(0xFF3D2317),
                ],
              ),
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(24)),
              border: Border.all(
                color: Colors.amber[700]!.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(-6, 0),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'برنامه‌های تمرینی ذخیره‌شده',
                          style: TextStyle(
                            color: Colors.amber[200],
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.amber[700]?.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.amber[700]!.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: IconButton(
                            icon: Icon(LucideIcons.x, color: Colors.amber[700]),
                            onPressed: onClose,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : savedPrograms.isEmpty
                            ? Center(
                                child: Text(
                                  'برنامه‌ای ذخیره نشده',
                                  style: TextStyle(
                                    color: Colors.amber[300],
                                    fontSize: 16,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                itemCount: savedPrograms.length,
                                separatorBuilder: (_, __) => const Divider(
                                    color: Colors.amber, height: 1),
                                itemBuilder: (context, index) {
                                  final program = savedPrograms[index];
                                  return ListTile(
                                    title: Text(program.name,
                                        style: const TextStyle(
                                            color: Colors.amber)),
                                    subtitle: Text(
                                        'تعداد سشن: ${program.sessions.length}',
                                        style: const TextStyle(
                                            color: Colors.amberAccent)),
                                    onTap: () => onSelect(program.id),
                                  );
                                },
                              ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('برنامه جدید'),
                      onPressed: onCreateNew,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber[700],
                        foregroundColor: Colors.black,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
