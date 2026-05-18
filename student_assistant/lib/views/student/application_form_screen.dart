import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:student_assistant/models/application.dart';
import 'package:student_assistant/viewmodels/application_viewmodel.dart';

class ApplicationFormScreen extends StatefulWidget {
  final Application? application;

  const ApplicationFormScreen({
    super.key,
    this.application,
  });

  bool get isEditing => application != null;

  @override
  State<ApplicationFormScreen> createState() =>
      _ApplicationFormScreenState();
}

class _ApplicationFormScreenState
    extends State<ApplicationFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late String _yearOfStudy;
  late List<ApplicationModule> _modules;
  late bool _eligibilityConfirmed;

  // DOCUMENTS
  PickedDocument? _idDocument;
  PickedDocument? _matricDocument;
  PickedDocument? _academicRecord;
  PickedDocument? _cvDocument;

  final List<String> _years = const [
    '1st Year',
    '2nd Year',
    '3rd Year',
  ];

  final List<String> _levels = const [
    '1st Year Module',
    '2nd Year Module',
    '3rd Year Module',
  ];

  @override
  void initState() {
    super.initState();

    final app = widget.application;

    _yearOfStudy =
        app?.yearOfStudy ?? '1st Year';

    _modules = app?.modules
            .map(
              (module) => ApplicationModule(
                academicLevel:
                    module.academicLevel,
                moduleName:
                    module.moduleName,
              ),
            )
            .toList() ??
        [
          const ApplicationModule(
            academicLevel:
                '1st Year Module',
            moduleName: '',
          ),
        ];

    _eligibilityConfirmed =
        app?.eligibilityConfirmed ?? false;
  }

  void _addModule() {
    if (_modules.length >= 2) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Only two modules are allowed.',
          ),
        ),
      );

      return;
    }

    setState(() {
      _modules.add(
        const ApplicationModule(
          academicLevel:
              '1st Year Module',
          moduleName: '',
        ),
      );
    });
  }

  void _removeModule(int index) {
    if (_modules.length == 1) return;

    setState(() {
      _modules.removeAt(index);
    });
  }

  Future<void> _pickFile(
    String documentType,
  ) async {
    final result =
        await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );

    final file = result?.files.single;
    final bytes = file?.bytes;

    if (file == null || bytes == null) {
      return;
    }

    final pickedDocument =
        PickedDocument(
      fileName: file.name,
      bytes: bytes,
    );

    setState(() {
      switch (documentType) {
        case 'id':
          _idDocument =
              pickedDocument;
          break;

        case 'matric':
          _matricDocument =
              pickedDocument;
          break;

        case 'academic':
          _academicRecord =
              pickedDocument;
          break;
          case 'cv':
  _cvDocument =
      pickedDocument;
  break;
      }
    });
  }

  Future<void> _saveApplication() async {
    final messenger =
        ScaffoldMessenger.of(context);

    final navigator =
        Navigator.of(context);

    final appVM =
        context.read<ApplicationViewModel>();

    if (!_formKey.currentState!
        .validate()) {
      return;
    }

    if (!_eligibilityConfirmed) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Please confirm eligibility.',
          ),
        ),
      );

      return;
    }

    if (!widget.isEditing &&
        (_idDocument == null ||
            _matricDocument ==
                null ||
            _academicRecord ==
                null ||
                _cvDocument == null)) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Please upload all required documents.',
          ),
        ),
      );

      return;
    }

    try {
      if (widget.isEditing) {
        await appVM.updateApplication(
          application:
              widget.application!,
          yearOfStudy:
              _yearOfStudy,
          modules: _modules,
          eligibilityConfirmed:
              _eligibilityConfirmed,

          // OPTIONAL DURING EDIT
          idDocument:
              _idDocument,
          matricDocument:
              _matricDocument,
          academicRecord:
              _academicRecord,
          cvDocument:
              _cvDocument,
        );
      } else {
        await appVM.submitApplication(
          yearOfStudy:
              _yearOfStudy,
          modules: _modules,
          eligibilityConfirmed:
              _eligibilityConfirmed,

          idDocument:
              _idDocument!,

          matricDocument:
              _matricDocument!,

          academicRecord:
              _academicRecord!,
             cvDocument:
    _cvDocument!, 
        );
      }

      if (!mounted) return;

      navigator.pop();

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditing
                ? 'Application updated successfully.'
                : 'Application submitted successfully.',
          ),
        ),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content:
              Text(error.toString()),
        ),
      );
    }
  }

  Widget _buildDocumentCard({
    required String title,
    required IconData icon,
    required PickedDocument? document,
    required VoidCallback onPressed,
  }) {
    return Container(
      padding:
          const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(
          20,
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets
                        .all(14),

                decoration:
                    BoxDecoration(
                  color: Colors
                      .indigo
                      .shade50,

                  borderRadius:
                      BorderRadius
                          .circular(
                    14,
                  ),
                ),

                child: Icon(
                  icon,
                  color:
                      Colors.indigo,
                ),
              ),

              const SizedBox(
                  width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                  children: [
                    Text(
                      title,

                      style:
                          const TextStyle(
                        fontWeight:
                            FontWeight
                                .bold,
                      ),
                    ),

                    const SizedBox(
                        height: 4),

                    Text(
                      document
                              ?.fileName ??
                          'No document selected',
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,

            child:
                ElevatedButton.icon(
              onPressed:
                  onPressed,

              style:
                  ElevatedButton
                      .styleFrom(
                backgroundColor:
                    Colors.indigo,

                foregroundColor:
                    Colors.white,

                padding:
                    const EdgeInsets
                        .symmetric(
                  vertical: 15,
                ),

                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius
                          .circular(
                    14,
                  ),
                ),
              ),

              icon: const Icon(
                Icons.upload,
              ),

              label: Text(
                'Upload $title',
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appVM =
        context.watch<ApplicationViewModel>();

    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F7FA),

      appBar: AppBar(
        elevation: 0,
        backgroundColor:
            Colors.white,
        foregroundColor:
            Colors.black,

        title: Text(
          widget.isEditing
              ? 'Edit Application'
              : 'Submit Application',

          style: const TextStyle(
            fontWeight:
                FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(22),

        child: Form(
          key: _formKey,

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,

            children: [
              // HEADER
              Container(
                width:
                    double.infinity,

                padding:
                    const EdgeInsets
                        .all(24),

                decoration:
                    BoxDecoration(
                  gradient:
                      const LinearGradient(
                    colors: [
                      Colors.indigo,
                      Colors.blue,
                    ],
                  ),

                  borderRadius:
                      BorderRadius
                          .circular(
                    24,
                  ),
                ),

                child:
                    const Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                  children: [
                    Icon(
                      Icons.school,
                      color:
                          Colors.white,
                      size: 42,
                    ),

                    SizedBox(
                        height: 16),

                    Text(
                      'Student Assistant Application',

                      style:
                          TextStyle(
                        fontSize: 28,
                        fontWeight:
                            FontWeight
                                .bold,
                        color: Colors
                            .white,
                      ),
                    ),

                    SizedBox(
                        height: 10),

                    Text(
                      'Apply for one or two modules only.',

                      style:
                          TextStyle(
                        color: Colors
                            .white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                  height: 24),

              // ACADEMIC INFO
              Container(
                padding:
                    const EdgeInsets
                        .all(20),

                decoration:
                    BoxDecoration(
                  color:
                      Colors.white,

                  borderRadius:
                      BorderRadius
                          .circular(
                    20,
                  ),
                ),

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons
                              .person_outline,
                          color: Colors
                              .indigo,
                        ),

                        SizedBox(
                            width:
                                10),

                        Text(
                          'Academic Information',

                          style:
                              TextStyle(
                            fontSize:
                                20,
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                        height: 20),

                    DropdownButtonFormField<
                        String>(
                      value:
                          _yearOfStudy,

                      decoration:
                          const InputDecoration(
                        labelText:
                            'Current Year of Study',

                        prefixIcon:
                            Icon(
                          Icons.school,
                        ),
                      ),

                      items: _years
                          .map(
                            (year) =>
                                DropdownMenuItem(
                              value:
                                  year,
                              child: Text(
                                  year),
                            ),
                          )
                          .toList(),

                      onChanged:
                          (value) {
                        setState(() {
                          _yearOfStudy =
                              value!;
                        });
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(
                  height: 24),

              // MODULE TITLE
              const Row(
                children: [
                  Icon(
                    Icons.menu_book,
                    color:
                        Colors.indigo,
                  ),

                  SizedBox(width: 10),

                  Text(
                    'Module Information',

                    style: TextStyle(
                      fontSize: 22,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(
                  height: 18),

              // MODULES
              ..._modules
                  .asMap()
                  .entries
                  .map((entry) {
                final index =
                    entry.key;

                final module =
                    entry.value;

                return Container(
                  margin:
                      const EdgeInsets
                          .only(
                    bottom: 18,
                  ),

                  padding:
                      const EdgeInsets
                          .all(20),

                  decoration:
                      BoxDecoration(
                    color:
                        Colors.white,

                    borderRadius:
                        BorderRadius
                            .circular(
                      20,
                    ),

                    boxShadow: const [
                      BoxShadow(
                        color: Colors
                            .black12,
                        blurRadius:
                            6,
                        offset:
                            Offset(
                                0,
                                2),
                      ),
                    ],
                  ),

                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(
                            'Module ${index + 1}',

                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight
                                      .bold,
                              fontSize:
                                  18,
                            ),
                          ),

                          const Spacer(),

                          if (_modules
                                  .length >
                              1)
                            IconButton(
                              tooltip:
                                  'Remove module',

                              onPressed:
                                  () =>
                                      _removeModule(
                                index,
                              ),

                              icon:
                                  const Icon(
                                Icons
                                    .delete_outline,
                                color:
                                    Colors
                                        .red,
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(
                          height: 18),

                      DropdownButtonFormField<
                          String>(
                        value: module
                            .academicLevel,

                        decoration:
                            const InputDecoration(
                          labelText:
                              'Academic Level',

                          prefixIcon:
                              Icon(
                            Icons
                                .layers,
                          ),
                        ),

                        items: _levels
                            .map(
                              (level) =>
                                  DropdownMenuItem(
                                value:
                                    level,
                                child:
                                    Text(
                                  level,
                                ),
                              ),
                            )
                            .toList(),

                        onChanged:
                            (value) {
                          setState(() {
                            _modules[index] =
                                ApplicationModule(
                              academicLevel:
                                  value!,
                              moduleName:
                                  module
                                      .moduleName,
                            );
                          });
                        },
                      ),

                      const SizedBox(
                          height: 18),

                      TextFormField(
                        controller:
                            TextEditingController(
                          text: module
                              .moduleName,
                        ),

                        decoration:
                            const InputDecoration(
                          labelText:
                              'Module Name / Code',

                          hintText:
                              'TPG316C',

                          prefixIcon:
                              Icon(
                            Icons
                                .book_outlined,
                          ),
                        ),

                        validator:
                            (value) {
                          if (value ==
                                  null ||
                              value
                                  .trim()
                                  .isEmpty) {
                            return 'Enter module name or code';
                          }

                          return null;
                        },

                        onChanged:
                            (value) {
                          _modules[index] =
                              ApplicationModule(
                            academicLevel:
                                _modules[index]
                                    .academicLevel,

                            moduleName:
                                value
                                    .trim(),
                          );
                        },
                      ),
                    ],
                  ),
                );
              }),

              if (_modules.length < 2)
                OutlinedButton.icon(
                  onPressed:
                      _addModule,

                  icon:
                      const Icon(
                    Icons.add,
                  ),

                  label:
                      const Text(
                    'Add Second Module',
                  ),
                ),

              const SizedBox(
                  height: 24),

              // ELIGIBILITY
              Container(
                padding:
                    const EdgeInsets
                        .all(20),

                decoration:
                    BoxDecoration(
                  color:
                      Colors.white,

                  borderRadius:
                      BorderRadius
                          .circular(
                    20,
                  ),
                ),

                child:
                    CheckboxListTile(
                  value:
                      _eligibilityConfirmed,

                  onChanged:
                      (value) {
                    setState(() {
                      _eligibilityConfirmed =
                          value ??
                              false;
                    });
                  },

                  title:
                      const Text(
                    'I confirm that I meet the minimum requirements.',
                  ),

                  subtitle:
                      const Text(
                    'Final decisions remain with administrative users.',
                  ),

                  controlAffinity:
                      ListTileControlAffinity
                          .leading,

                  contentPadding:
                      EdgeInsets.zero,
                ),
              ),

              const SizedBox(
                  height: 24),

              // DOCUMENTS
              _buildDocumentCard(
                title: 'ID Copy',
                icon: Icons
                    .badge_outlined,
                document:
                    _idDocument,
                onPressed: () =>
                    _pickFile(
                        'id'),
              ),

              const SizedBox(
                  height: 18),

              _buildDocumentCard(
                title:
                    'Matric Results',
                icon: Icons
                    .school_outlined,
                document:
                    _matricDocument,
                onPressed: () =>
                    _pickFile(
                        'matric'),
              ),

              const SizedBox(
                  height: 18),

              _buildDocumentCard(
                title:
                    'Academic Record',
                icon: Icons
                    .menu_book_outlined,
                document:
                    _academicRecord,
                onPressed: () =>
                    _pickFile(
                        'academic'),
              ),
              const SizedBox(
    height: 18),

_buildDocumentCard(
  title: 'Curriculum Vitae (CV)',

  icon:
      Icons.description_outlined,

  document:
      _cvDocument,

  onPressed: () =>
      _pickFile('cv'),
),

              const SizedBox(
                  height: 30),

              // SUBMIT
              SizedBox(
                width:
                    double.infinity,

                child:
                    ElevatedButton
                        .icon(
                  onPressed:
                      appVM.isLoading
                          ? null
                          : _saveApplication,

                  style:
                      ElevatedButton
                          .styleFrom(
                    backgroundColor:
                        Colors
                            .indigo,

                    foregroundColor:
                        Colors.white,

                    padding:
                        const EdgeInsets
                            .symmetric(
                      vertical:
                          18,
                    ),

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                        18,
                      ),
                    ),
                  ),

                  icon: appVM
                          .isLoading
                      ? const SizedBox(
                          width:
                              18,
                          height:
                              18,
                          child:
                              CircularProgressIndicator(
                            strokeWidth:
                                2,
                            color:
                                Colors
                                    .white,
                          ),
                        )
                      : const Icon(
                          Icons
                              .save,
                        ),

                  label: Text(
                    widget
                            .isEditing
                        ? 'Save Changes'
                        : 'Submit Application',

                    style:
                        const TextStyle(
                      fontSize:
                          16,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                  height: 30),
            ],
          ),
        ),
      ),
    );
  }
}