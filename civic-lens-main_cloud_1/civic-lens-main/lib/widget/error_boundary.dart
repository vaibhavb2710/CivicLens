import 'package:flutter/material.dart';

class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final Widget? errorWidget;
  final Function(Object error, StackTrace stackTrace)? onError;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.errorWidget,
    this.onError,
  });

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  bool _hasError = false;
  Object? _error;
  StackTrace? _stackTrace;

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return widget.errorWidget ?? _buildDefaultErrorWidget();
    }
    
    return ErrorDetector(
      onError: (error, stackTrace) {
        if (mounted) {
          setState(() {
            _hasError = true;
            _error = error;
            _stackTrace = stackTrace;
          });
        }
        widget.onError?.call(error, stackTrace);
      },
      child: widget.child,
    );
  }

  Widget _buildDefaultErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          const Text(
            'Something went wrong',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please try refreshing the page',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _hasError = false;
                _error = null;
                _stackTrace = null;
              });
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}

class ErrorDetector extends StatelessWidget {
  final Widget child;
  final Function(Object error, StackTrace stackTrace) onError;

  const ErrorDetector({
    super.key,
    required this.child,
    required this.onError,
  });

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        try {
          return child;
        } catch (error, stackTrace) {
          onError(error, stackTrace);
          return Container(
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
      },
    );
  }
}