
import 'package:flutter/material.dart';
import 'api/api_client.dart';
import 'models.dart';

class CourseEditorPage extends StatefulWidget {
  final Course? course;

  const CourseEditorPage({super.key, this.course});

  @override
  State<CourseEditorPage> createState() => _CourseEditorPageState();
}

class _CourseEditorPageState extends State<CourseEditorPage> {
  final _formKey = GlobalKey<FormState>();
  final _apiClient = ApiClient();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _shortDescController;
  late TextEditingController _priceController;
  late TextEditingController _levelController;
  late TextEditingController _languageController;
  late TextEditingController _categoryController;
  late TextEditingController _thumbnailController;
  late TextEditingController _previewVideoController;
  bool _isPublished = false;
  String? _thumbnailUrl;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.course?.title);
    _descriptionController = TextEditingController(text: widget.course?.description);
    _shortDescController = TextEditingController(text: widget.course?.shortDesc);
    _priceController = TextEditingController(text: widget.course?.price.toString());
    _levelController = TextEditingController(text: widget.course?.level);
    _languageController = TextEditingController(text: widget.course?.language);
    _categoryController = TextEditingController(text: widget.course?.category);
    _thumbnailController = TextEditingController(text: widget.course?.thumbnail);
    _previewVideoController = TextEditingController(text: widget.course?.previewVideo);
    _isPublished = widget.course?.isPublished ?? false;
    _thumbnailUrl = widget.course?.thumbnail;

    _thumbnailController.addListener(() {
      setState(() {
        _thumbnailUrl = _thumbnailController.text;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.course == null ? '新增課程' : '編輯課程'),
        actions: [
          if (widget.course != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('刪除課程?'),
                    content: const Text('你確定要刪除此課程嗎?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('取消'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('刪除'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  await _apiClient.deleteCourse(widget.course!.id);
                  Navigator.pop(context);
                }
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: '標題'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '請輸入標題';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: '描述'),
                maxLines: 3,
              ),
              TextFormField(
                controller: _shortDescController,
                decoration: const InputDecoration(labelText: '簡短描述'),
              ),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: '價格'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _levelController,
                decoration: const InputDecoration(labelText: '難度'),
              ),
              TextFormField(
                controller: _languageController,
                decoration: const InputDecoration(labelText: '語言'),
              ),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: '分類'),
              ),
              TextFormField(
                controller: _thumbnailController,
                decoration: const InputDecoration(labelText: '縮圖網址'),
              ),
              if (_thumbnailUrl != null && _thumbnailUrl!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Image.network(
                    _thumbnailUrl!,
                    height: 150,
                    errorBuilder: (context, error, stackTrace) {
                      return const Text('無法載入圖片');
                    },
                  ),
                ),
              TextFormField(
                controller: _previewVideoController,
                decoration: const InputDecoration(labelText: '預覽影片網址'),
              ),
              SwitchListTile(
                title: const Text('發布'),
                value: _isPublished,
                onChanged: (value) {
                  setState(() {
                    _isPublished = value;
                  });
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final course = Course(
                      id: widget.course?.id ?? 0,
                      title: _titleController.text,
                      description: _descriptionController.text,
                      shortDesc: _shortDescController.text,
                      price: double.parse(_priceController.text),
                      level: _levelController.text,
                      language: _languageController.text,
                      category: _categoryController.text,
                      thumbnail: _thumbnailController.text,
                      previewVideo: _previewVideoController.text,
                      isPublished: _isPublished,
                      createdAt: widget.course?.createdAt ?? '',
                    );

                    if (widget.course == null) {
                      await _apiClient.createCourse(course);
                    } else {
                      await _apiClient.updateCourse(course);
                    }

                    Navigator.pop(context);
                  }
                },
                child: const Text('儲存'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
