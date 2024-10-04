import 'package:crimewalksapp/crime_walk.dart';
import 'package:crimewalksapp/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class StartWalkButton extends StatefulWidget
{
  const StartWalkButton({super.key, required this.model, required this.callback, required this.walk});

  final CrimeWalkModel model;
  final Function callback;
  final CrimeWalk walk;

  @override
  _StartWalkButtonState createState() => _StartWalkButtonState();
}

class _StartWalkButtonState extends State<StartWalkButton> with SingleTickerProviderStateMixin
{
  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: () {
        setState(() {
          userSettings.startWalk(widget.walk, widget.model);
        });

        widget.callback();
      },
      child: const Text("Start Walk")
    );
  }
}

class CancelWalkButton extends StatefulWidget
{
  const CancelWalkButton({super.key, required this.model, required this.callback});

  final CrimeWalkModel model;
  final Function callback;

  @override
  _CancelWalkButtonState createState() => _CancelWalkButtonState();
}

class _CancelWalkButtonState extends State<CancelWalkButton> with SingleTickerProviderStateMixin
{
  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: () {
        setState(() {
          userSettings.cancelWalk(widget.model);
        });

        widget.callback();
      },
      child: const Text("Cancel Walk")
    );
  }
}