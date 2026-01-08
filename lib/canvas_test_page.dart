import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:js' as js;

/// Halaman test sederhana untuk memverifikasi canvas overlay
/// File: lib/canvas_test_page.dart
class CanvasTestPage extends StatefulWidget {
  const CanvasTestPage({Key? key}) : super(key: key);

  @override
  State<CanvasTestPage> createState() => _CanvasTestPageState();
}

class _CanvasTestPageState extends State<CanvasTestPage> {
  String _debugInfo = '';
  bool _canvasCreated = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 1), () {
      _createTestCanvas();
    });
  }

  void _createTestCanvas() {
    try {
      // Buat canvas test
      final canvas = html.CanvasElement()
        ..width = 600
        ..height = 400
        ..id = 'test-canvas'
        ..style.position = 'fixed'
        ..style.top = '50%'
        ..style.left = '50%'
        ..style.transform = 'translate(-50%, -50%)'
        ..style.zIndex = '99999'
        ..style.border = '10px solid red'
        ..style.backgroundColor = 'rgba(0, 0, 255, 0.3)'
        ..style.boxShadow = '0 0 30px rgba(255, 0, 0, 0.8)';

      // Append ke body
      html.document.body!.append(canvas);

      print('✅ Canvas appended to body');

      // Gambar sesuatu di canvas
      final ctx = canvas.getContext('2d') as html.CanvasRenderingContext2D;
      
      // Background
      ctx.fillStyle = 'rgba(255, 255, 0, 0.7)';
      ctx.fillRect(0, 0, 600, 400);
      
      // Border dalam
      ctx.strokeStyle = 'blue';
      ctx.lineWidth = 5;
      ctx.strokeRect(10, 10, 580, 380);
      
      // Text besar
      ctx.fillStyle = 'black';
      ctx.font = 'bold 40px Arial';
      ctx.fillText('✓ CANVAS TEST', 150, 100);
      
      ctx.font = 'bold 30px Arial';
      ctx.fillText('Jika terlihat,', 180, 180);
      ctx.fillText('canvas WORKING!', 150, 220);
      
      // Circle
      ctx.fillStyle = 'red';
      ctx.beginPath();
      ctx.arc(300, 300, 60, 0, 2 * 3.14159);
      ctx.fill();
      
      // Circle border
      ctx.strokeStyle = 'white';
      ctx.lineWidth = 5;
      ctx.stroke();

      print('✅ Canvas drawn');

      // Update debug info
      setState(() {
        _canvasCreated = true;
        _debugInfo = '''
✅ Canvas Created Successfully!

Canvas Properties:
━━━━━━━━━━━━━━━━━━━━━━
ID: ${canvas.id}
Position: ${canvas.style.position}
Top: ${canvas.style.top}
Left: ${canvas.style.left}
Z-Index: ${canvas.style.zIndex}
Width: ${canvas.width}px
Height: ${canvas.height}px
In DOM: ${html.document.body!.contains(canvas)}
        ''';
      });

      // Tambahkan test via JavaScript
      js.context.callMethod('eval', [
        '''
        (function() {
          console.log('=== CANVAS TEST ===');
          var canvas = document.getElementById('test-canvas');
          console.log('Canvas element:', canvas);
          console.log('Canvas visible:', canvas !== null);
          console.log('Canvas in body:', document.body.contains(canvas));
          console.log('Canvas position:', canvas.style.position);
          console.log('Canvas z-index:', canvas.style.zIndex);
          console.log('Canvas display:', canvas.style.display);
          console.log('Canvas visibility:', canvas.style.visibility);
          console.log('===================');
        })()
        '''
      ]);
    } catch (e) {
      print('❌ Error creating canvas: $e');
      setState(() {
        _debugInfo = '❌ ERROR: $e';
      });
    }
  }

  void _removeCanvas() {
    final canvas = html.document.getElementById('test-canvas');
    if (canvas != null) {
      canvas.remove();
      setState(() {
        _canvasCreated = false;
        _debugInfo = 'Canvas removed';
      });
      print('Canvas removed');
    }
  }

  @override
  void dispose() {
    _removeCanvas();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      appBar: AppBar(
        title: const Text('Canvas Overlay Test'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: Icon(_canvasCreated ? Icons.visibility_off : Icons.visibility),
            onPressed: () {
              if (_canvasCreated) {
                _removeCanvas();
              } else {
                _createTestCanvas();
              }
            },
            tooltip: _canvasCreated ? 'Hide Canvas' : 'Show Canvas',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade700, Colors.blue.shade900],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                children: [
                  Icon(Icons.science, color: Colors.white, size: 48),
                  SizedBox(height: 10),
                  Text(
                    'Canvas Overlay Test',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Verifikasi canvas dapat muncul di atas Flutter widget',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Expected Result
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.checklist, color: Colors.green, size: 24),
                      SizedBox(width: 10),
                      Text(
                        'Yang Harus Terlihat:',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 15),
                  Text('✓ Kotak besar di tengah layar',
                      style: TextStyle(color: Colors.white, fontSize: 15)),
                  SizedBox(height: 8),
                  Text('✓ Border merah SANGAT TEBAL (10px)',
                      style: TextStyle(color: Colors.white, fontSize: 15)),
                  SizedBox(height: 8),
                  Text('✓ Background kuning semi-transparan',
                      style: TextStyle(color: Colors.white, fontSize: 15)),
                  SizedBox(height: 8),
                  Text('✓ Text hitam "✓ CANVAS TEST"',
                      style: TextStyle(color: Colors.white, fontSize: 15)),
                  SizedBox(height: 8),
                  Text('✓ Text "Jika terlihat, canvas WORKING!"',
                      style: TextStyle(color: Colors.white, fontSize: 15)),
                  SizedBox(height: 8),
                  Text('✓ Lingkaran merah besar di bawah',
                      style: TextStyle(color: Colors.white, fontSize: 15)),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Status
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _canvasCreated 
                    ? Colors.green.shade900 
                    : Colors.orange.shade900,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _canvasCreated ? Colors.green : Colors.orange,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _canvasCreated ? Icons.check_circle : Icons.pending,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      _canvasCreated 
                          ? 'Canvas Active' 
                          : 'Waiting for canvas...',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Debug Info
            if (_debugInfo.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.cyan, width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.cyan, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Debug Information:',
                          style: TextStyle(
                            color: Colors.cyan,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _debugInfo,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'monospace',
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 20),
            
            // Instructions
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade900.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue, width: 1),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: Colors.yellow, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Tips:',
                        style: TextStyle(
                          color: Colors.yellow,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Text(
                    '• Buka Browser Console (F12) untuk melihat log detail',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  SizedBox(height: 5),
                  Text(
                    '• Canvas harus muncul DI ATAS semua widget Flutter',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  SizedBox(height: 5),
                  Text(
                    '• Jika tidak terlihat, ada masalah dengan z-index atau positioning',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}