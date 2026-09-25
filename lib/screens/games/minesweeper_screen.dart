import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:oreui_flutter/oreui_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../widgets/ore_button.dart';

enum Difficulty { easy, medium, hard, custom }

class DifficultyConfig {
  final int rows;
  final int cols;
  final int mines;
  const DifficultyConfig(this.rows, this.cols, this.mines);

  static const easy = DifficultyConfig(9, 9, 10);
  static const medium = DifficultyConfig(16, 16, 40);
  static const hard = DifficultyConfig(16, 30, 99);
}

/// Complete Minesweeper with flagging, timer, win/lose, best times.
class MinesweeperScreen extends StatefulWidget {
  const MinesweeperScreen({super.key});

  @override
  State<MinesweeperScreen> createState() => _MinesweeperScreenState();
}

class _Cell {
  bool mine = false;
  bool revealed = false;
  bool flagged = false;
  int adjacent = 0;
}

class _MinesweeperScreenState extends State<MinesweeperScreen> {
  Difficulty _difficulty = Difficulty.easy;
  DifficultyConfig _config = DifficultyConfig.easy;
  int _customRows = 12;
  int _customCols = 12;
  int _customMines = 20;

  late List<List<_Cell>> _grid;
  bool _started = false;
  bool _gameOver = false;
  bool _won = false;
  int _revealed = 0;
  int _flags = 0;
  Timer? _timer;
  int _seconds = 0;
  Map<String, int> _best = {};

  @override
  void initState() {
    super.initState();
    _newGame();
    _loadBest();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadBest() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _best = {
        'easy': prefs.getInt('ms_best_easy') ?? 0,
        'medium': prefs.getInt('ms_best_medium') ?? 0,
        'hard': prefs.getInt('ms_best_hard') ?? 0,
      };
    });
  }

  Future<void> _saveBest() async {
    if (!_won) return;
    final key = _difficulty.name;
    final prev = _best[key] ?? 0;
    if (prev == 0 || _seconds < prev) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('ms_best_$key', _seconds);
      setState(() => _best[key] = _seconds);
    }
  }

  void _newGame() {
    _timer?.cancel();
    setState(() {
      _grid = List.generate(
        _config.rows,
        (_) => List.generate(_config.cols, (_) => _Cell()),
      );
      _started = false;
      _gameOver = false;
      _won = false;
      _revealed = 0;
      _flags = 0;
      _seconds = 0;
    });
  }

  void _setDifficulty(Difficulty d) {
    setState(() {
      _difficulty = d;
      if (d == Difficulty.easy) _config = DifficultyConfig.easy;
      if (d == Difficulty.medium) _config = DifficultyConfig.medium;
      if (d == Difficulty.hard) _config = DifficultyConfig.hard;
      if (d == Difficulty.custom) {
        _config = DifficultyConfig(_customRows, _customCols, _customMines);
      }
    });
    _newGame();
  }

  void _placeMines(int safeR, int safeC) {
    final rand = Random();
    int placed = 0;
    final total = _config.rows * _config.cols;
    final mines = _config.mines.clamp(1, total - 1);
    while (placed < mines) {
      final r = rand.nextInt(_config.rows);
      final c = rand.nextInt(_config.cols);
      if ((r == safeR && c == safeC) || _grid[r][c].mine) continue;
      _grid[r][c].mine = true;
      placed++;
    }
    for (var r = 0; r < _config.rows; r++) {
      for (var c = 0; c < _config.cols; c++) {
        if (_grid[r][c].mine) continue;
        int count = 0;
        for (var dr = -1; dr <= 1; dr++) {
          for (var dc = -1; dc <= 1; dc++) {
            if (dr == 0 && dc == 0) continue;
            final nr = r + dr;
            final nc = c + dc;
            if (nr < 0 ||
                nc < 0 ||
                nr >= _config.rows ||
                nc >= _config.cols) {
              continue;
            }
            if (_grid[nr][nc].mine) count++;
          }
        }
        _grid[r][c].adjacent = count;
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
  }

  void _reveal(int r, int c) {
    if (_gameOver || _grid[r][c].revealed || _grid[r][c].flagged) return;
    if (!_started) {
      _placeMines(r, c);
      _started = true;
      _startTimer();
    }
    setState(() {
      _flood(r, c);
      if (_grid[r][c].mine) {
        _gameOver = true;
        _timer?.cancel();
        _revealAllMines();
        return;
      }
      final total = _config.rows * _config.cols;
      if (_revealed == total - _config.mines.clamp(1, total - 1)) {
        _gameOver = true;
        _won = true;
        _timer?.cancel();
        _saveBest();
      }
    });
  }

  void _flood(int r, int c) {
    if (r < 0 || c < 0 || r >= _config.rows || c >= _config.cols) return;
    final cell = _grid[r][c];
    if (cell.revealed || cell.flagged) return;
    cell.revealed = true;
    if (cell.mine) return;
    _revealed++;
    if (cell.adjacent == 0) {
      for (var dr = -1; dr <= 1; dr++) {
        for (var dc = -1; dc <= 1; dc++) {
          if (dr == 0 && dc == 0) continue;
          _flood(r + dr, c + dc);
        }
      }
    }
  }

  void _revealAllMines() {
    for (final row in _grid) {
      for (final cell in row) {
        if (cell.mine) cell.revealed = true;
      }
    }
  }

  void _toggleFlag(int r, int c) {
    if (_gameOver || _grid[r][c].revealed) return;
    setState(() {
      _grid[r][c].flagged = !_grid[r][c].flagged;
      _flags += _grid[r][c].flagged ? 1 : -1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ore = OreTheme.of(context);
    final remaining = _config.mines - _flags;
    return Scaffold(
      backgroundColor: ore.colors.background,
      appBar: AppBar(
        backgroundColor: ore.colors.background,
        title: Text('MangoZ Minesweeper',
            style: ore.typography.choiceTitle),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh), onPressed: _newGame),
        ],
      ),
      body: Column(
        children: [
          OreStrip(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _hud(ore, '💣 $remaining'),
                const Spacer(),
                _hud(ore, _won ? '🏆 $_seconds s' : '⏱ $_seconds s'),
                const Spacer(),
                _hud(ore, _gameOver ? (_won ? '😎' : '💥') : '⛏'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Wrap(
              spacing: 6,
              children: [
                _diffChip(ore, 'Easy', Difficulty.easy),
                _diffChip(ore, 'Medium', Difficulty.medium),
                _diffChip(ore, 'Hard', Difficulty.hard),
                _diffChip(ore, 'Custom', Difficulty.custom),
              ],
            ),
          ),
          if (_difficulty == Difficulty.custom)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  _numField(ore, 'Rows', _customRows, (v) {
                    _customRows = v.clamp(6, 24);
                    _config = DifficultyConfig(
                        _customRows, _customCols, _customMines);
                    _newGame();
                  }),
                  const SizedBox(width: 8),
                  _numField(ore, 'Cols', _customCols, (v) {
                    _customCols = v.clamp(6, 30);
                    _config = DifficultyConfig(
                        _customRows, _customCols, _customMines);
                    _newGame();
                  }),
                  const SizedBox(width: 8),
                  _numField(ore, 'Mines', _customMines, (v) {
                    _customMines = v.clamp(
                        5, _customRows * _customCols - 1);
                    _config = DifficultyConfig(
                        _customRows, _customCols, _customMines);
                    _newGame();
                  }),
                ],
              ),
            ),
          if (_gameOver)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                _won
                    ? 'You win! Time: $_seconds s 🎉'
                    : 'Boom! Tap restart to try again.',
                style: ore.typography.label.copyWith(
                  color: _won
                      ? ore.colors.success
                      : ore.colors.danger,
                ),
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(8),
              child: Center(
                child: Column(
                  children: List.generate(_config.rows, (r) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(_config.cols, (c) {
                        return _cellWidget(ore, r, c);
                      }),
                    );
                  }),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              'Best — Easy: ${_fmtBest('easy')} · Medium: ${_fmtBest('medium')} · Hard: ${_fmtBest('hard')}',
              style: ore.typography.caption,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  String _fmtBest(String key) {
    final v = _best[key] ?? 0;
    return v == 0 ? '—' : '${v}s';
  }

  Widget _hud(OreThemeData ore, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: ore.colors.surfaceDark,
        border: Border.all(
            color: ore.colors.border, width: ore.borderWidth),
      ),
      child: Text(text, style: ore.typography.label),
    );
  }

  Widget _diffChip(
      OreThemeData ore, String label, Difficulty d) {
    final selected = _difficulty == d;
    return MangoOreButton(
      onPressed: () => _setDifficulty(d),
      variant: selected
          ? OreButtonVariant.primary
          : OreButtonVariant.secondary,
      size: OreButtonSize.sm,
      child: Text(label),
    );
  }

  Widget _numField(OreThemeData ore, String label, int value,
      ValueChanged<int> onChanged) {
    final controller =
        TextEditingController(text: '$value');
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: ore.typography.caption),
          OreTextField(
            controller: controller,
            keyboardType: TextInputType.number,
            onSubmitted: (v) {
              final n = int.tryParse(v);
              if (n != null) onChanged(n);
            },
          ),
        ],
      ),
    );
  }

  Widget _cellWidget(OreThemeData ore, int r, int c) {
    final cell = _grid[r][c];
    final hard = _difficulty == Difficulty.hard;
    final size = hard ? 26.0 : 34.0;
    Color bg;
    Widget? content;
    if (!cell.revealed) {
      bg = ore.colors.surface;
      if (cell.flagged) {
        content = Text('🚩',
            style: TextStyle(fontSize: size * 0.55));
      }
    } else if (cell.mine) {
      bg = ore.colors.danger;
      content =
          Text('💣', style: TextStyle(fontSize: size * 0.55));
    } else {
      bg = ore.colors.surfaceDark;
      if (cell.adjacent > 0) {
        content = Text(
          '${cell.adjacent}',
          style: ore.typography.label.copyWith(
            color: _numberColor(ore, cell.adjacent),
            fontSize: size * 0.5,
          ),
        );
      }
    }
    return GestureDetector(
      onTap: () => _reveal(r, c),
      onLongPress: () => _toggleFlag(r, c),
      onSecondaryTap: () => _toggleFlag(r, c),
      child: Container(
        width: size,
        height: size,
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(
              color: ore.colors.border, width: 1.5),
        ),
        alignment: Alignment.center,
        child: content,
      ),
    );
  }

  Color _numberColor(OreThemeData ore, int n) {
    const palette = [
      Colors.blue,
      Colors.green,
      Colors.red,
      Colors.purple,
      Colors.orange,
      Colors.teal,
      Colors.pink,
      Colors.yellow,
    ];
    if (n >= 1 && n <= palette.length) return palette[n - 1];
    return ore.colors.textPrimary;
  }
}
