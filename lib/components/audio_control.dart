import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:just_audio/just_audio.dart';
import 'package:sentry/sentry.dart';

var getIt = GetIt.instance;

class LifecycleEventHandler extends WidgetsBindingObserver {
  LifecycleEventHandler({this.resumeCallBack, this.detachedCallBack});

  VoidCallback resumeCallBack;
  VoidCallback detachedCallBack;

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        detachedCallBack();
        break;
      case AppLifecycleState.resumed:
        resumeCallBack();
        break;
    }
  }
}

class AudioControl extends StatefulWidget {
  AudioControl({Key key, this.networkSrc, this.autostart, this.colorsInverted})
      : super(key: key);
  final String networkSrc;
  final bool autostart;
  final bool colorsInverted;
  @override
  _AudioControlState createState() => _AudioControlState();
}

class _AudioControlState extends State<AudioControl> {
  bool audioMuted = false;
  bool isPlaying = false;
  bool dragging = false;
  double duration = 0.0;
  AudioPlayer player;
  bool isLoading = false;
  bool isError = false;
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(LifecycleEventHandler(
      detachedCallBack: () async => {},
      resumeCallBack: () async {
        try {
          if (player == null) {
            player = AudioPlayer();
            print(widget.networkSrc);
            duration =
                (await player.setUrl(widget.networkSrc)).inSeconds.toDouble();
          }
        } catch (error, stackTrace) {
          setState(() {
            isError = true;
          });
          await getIt<SentryClient>().captureException(
            exception: error,
            stackTrace: stackTrace,
          );
        }
      },
    ));

    if (player == null) player = AudioPlayer();
    _doInitStuff();
  }

  Future _doInitStuff() async {
    try {
      duration = (await player.setUrl(widget.networkSrc)).inSeconds.toDouble();
      if (widget.autostart) player.play();
    } catch (error, stackTrace) {
      print("Error: $e");
      await getIt<SentryClient>().captureException(
        exception: error,
        stackTrace: stackTrace,
      );
      setState(() {
        isError = true;
      });
    }
  }

  @override
  void dispose() async {
    super.dispose();
    await player.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: isError
          ? Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "There was en error playing the audio file.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white),
                )
              ],
            )
          : Row(
              children: [
                StreamBuilder<PlayerState>(
                  stream: player.playerStateStream,
                  builder: (context, snapshot) {
                    final playerState = snapshot.data;
                    final processingState = playerState?.processingState;
                    final playing = playerState?.playing;
                    if (processingState == ProcessingState.loading ||
                        processingState == ProcessingState.buffering) {
                      return Container(
                        width: 56,
                        height: 56,
                        child: Center(
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      );
                    } else if (playing != true) {
                      return Material(
                        color: Colors.transparent, // button color
                        child: InkWell(
                          splashColor: Colors.red, // inkwell color
                          child: SizedBox(
                              width: 56,
                              height: 56,
                              child: Icon(
                                Icons.play_arrow,
                                color: widget.colorsInverted
                                    ? Colors.white
                                    : Colors.black,
                              )),
                          onTap: player.play,
                        ),
                      );
                    } else if (processingState != ProcessingState.completed) {
                      return Material(
                        color: Colors.transparent, // button color
                        child: InkWell(
                          splashColor: Colors.red, // inkwell color
                          child: SizedBox(
                              width: 56,
                              height: 56,
                              child: Icon(
                                Icons.pause,
                                color: widget.colorsInverted
                                    ? Colors.white
                                    : Colors.black,
                              )),
                          onTap: player.pause,
                        ),
                      );
                    } else {
                      return Material(
                        color: Colors.transparent, // button color
                        child: InkWell(
                          splashColor: Colors.red, // inkwell color
                          child: SizedBox(
                              width: 56,
                              height: 56,
                              child: Icon(
                                Icons.replay,
                                color: widget.colorsInverted
                                    ? Colors.white
                                    : Colors.black,
                              )),
                          onTap: () => player.seek(Duration.zero, index: 0),
                        ),
                      );
                    }
                  },
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Colors.red[700],
                    inactiveTrackColor: Colors.red[100],
                    trackShape: RectangularSliderTrackShape(),
                    trackHeight: 4.0,
                    thumbColor: Colors.redAccent,
                    thumbShape: RoundSliderThumbShape(enabledThumbRadius: 12.0),
                    overlayColor: Colors.red.withAlpha(32),
                    overlayShape: RoundSliderOverlayShape(overlayRadius: 28.0),
                  ),
                  child: Expanded(
                      child: StreamBuilder<Duration>(
                    stream: player.durationStream,
                    builder: (context, snapshot) {
                      final duration = snapshot.data ?? Duration.zero;
                      return StreamBuilder<Duration>(
                        stream: player.positionStream,
                        builder: (context, snapshot) {
                          var position = snapshot.data ?? Duration.zero;
                          if (position > duration) {
                            position = duration;
                          }
                          return SeekBar(
                            duration: duration,
                            position: position,
                            onChangeEnd: (newPosition) {
                              player.seek(newPosition);
                            },
                          );
                        },
                      );
                    },
                  )),
                ),
                Material(
                  color: Colors.transparent, // button color
                  child: InkWell(
                    splashColor: Colors.red, // inkwell color
                    child: SizedBox(
                        width: 56,
                        height: 56,
                        child: audioMuted
                            ? Icon(
                                Icons.volume_off,
                                color: widget.colorsInverted
                                    ? Colors.white
                                    : Colors.black,
                              )
                            : Icon(
                                Icons.volume_up,
                                color: widget.colorsInverted
                                    ? Colors.white
                                    : Colors.black,
                              )),
                    onTap: () {
                      if (audioMuted) {
                        player.setVolume(1);
                        setState(() {
                          audioMuted = false;
                        });
                      } else {
                        player.setVolume(0);
                        setState(() {
                          audioMuted = true;
                        });
                      }
                    },
                  ),
                )
              ],
            ),
    );
  }
}

class SeekBar extends StatefulWidget {
  final Duration duration;
  final Duration position;
  final ValueChanged<Duration> onChanged;
  final ValueChanged<Duration> onChangeEnd;

  SeekBar({
    @required this.duration,
    @required this.position,
    this.onChanged,
    this.onChangeEnd,
  });

  @override
  _SeekBarState createState() => _SeekBarState();
}

class _SeekBarState extends State<SeekBar> {
  double _dragValue;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Slider(
          min: 0.0,
          max: widget.duration.inMilliseconds.toDouble(),
          value: min(_dragValue ?? widget.position.inMilliseconds.toDouble(),
              widget.duration.inMilliseconds.toDouble()),
          onChanged: (value) {
            setState(() {
              _dragValue = value;
            });
            if (widget.onChanged != null) {
              widget.onChanged(Duration(milliseconds: value.round()));
            }
          },
          onChangeEnd: (value) {
            if (widget.onChangeEnd != null) {
              widget.onChangeEnd(Duration(milliseconds: value.round()));
            }
            _dragValue = null;
          },
        ),
      ],
    );
  }
}
