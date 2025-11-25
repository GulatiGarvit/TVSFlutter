import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tvs/data.dart';
import 'package:tvs/providers/navigation.dart';
import 'package:tvs/providers/settings.dart';
import 'package:tvs/widgets/box_radio_group.dart';

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  String? _selectedAirport;

  late String _selectedUnit;

  @override
  Widget build(BuildContext context) {
    _selectedAirport =
        context.watch<SettingsProvider>().airportCode != null
            ? "${context.watch<SettingsProvider>().airportCode} - ${airportData[context.watch<SettingsProvider>().airportCode]!['name']}"
            : null;
    _selectedUnit = context.watch<SettingsProvider>().unitSystem;
    return AlertDialog(
      title: const Text('Settings'),
      content: Container(
        width: MediaQuery.of(context).size.width * 0.4,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  "Select Airport: ",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownSearch<String>(
                    items:
                        (f, cs) =>
                            airportData.entries
                                .map((e) => "${e.key} - ${e.value['name']}")
                                .toList(),
                    selectedItem: _selectedAirport,
                    popupProps: const PopupProps.menu(
                      showSearchBox: true,
                      searchFieldProps: TextFieldProps(
                        decoration: InputDecoration(
                          labelText: 'Search airport',
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                    ),
                    decoratorProps: const DropDownDecoratorProps(
                      decoration: InputDecoration(border: OutlineInputBorder()),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _selectedAirport = value;
                        if (_selectedAirport == null) return;

                        // Update in provider
                        context.read<SettingsProvider>().setAirportCode(
                          _selectedAirport!.split(" - ")[0],
                        );
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  "Measurement Units: ",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: BoxRadioGroup(
                    options: ["Nautical", "Metric", "Imperial"],
                    selected: _selectedUnit,
                    onChanged: (value) {
                      setState(() {
                        _selectedUnit = value;
                        context.read<SettingsProvider>().setUnitSystem(value);
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  backgroundColor: Colors.blueGrey,
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
