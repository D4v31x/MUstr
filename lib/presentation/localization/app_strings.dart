import 'package:flutter/material.dart';

class AppStrings {
  const AppStrings._(this._languageCode);

  final String _languageCode;

  static AppStrings of(BuildContext context) =>
      AppStrings._(Localizations.localeOf(context).languageCode);

  String get languageCode => _languageCode;

  String get today => _text('today');
  String get weekOverview => _text('weekOverview');
  String get previousWeek => _text('previousWeek');
  String get nextWeek => _text('nextWeek');
  String get semesterLabel => _text('semesterLabel');
  String get importedTimetable => _text('importedTimetable');
  String get addExam => _text('addExam');
  String get examPeriod => _text('examPeriod');
  String get exam => _text('exam');
  String get jumpToWeek => _text('jumpToWeek');
  String get deadlines => _text('deadlines');
  String get assessments => _text('assessments');
  String get noDeadlines => _text('noDeadlines');
  String get noExams => _text('noExams');
  String get independentExam => _text('independentExam');
  String get deleteExam => _text('deleteExam');
  String get addExamTitle => _text('addExamTitle');
  String get examTitle => _text('examTitle');
  String get examTitleRequired => _text('examTitleRequired');
  String get faculty => _text('faculty');
  String get subjectOptional => _text('subjectOptional');
  String get noSubject => _text('noSubject');
  String get roomOrOnlineLocation => _text('roomOrOnlineLocation');
  String get notesOptional => _text('notesOptional');
  String get saveExam => _text('saveExam');
  String get starts => _text('starts');
  String get ends => _text('ends');
  String get saveExamPeriod => _text('saveExamPeriod');
  String get invalidExamPeriod => _text('invalidExamPeriod');
  String get yourCourses => _text('yourCourses');
  String subjectsInTimetable(int count) =>
      _format('subjectsInTimetable', '$count');
  String scheduledClasses(int count) => _format('scheduledClasses', '$count');
  String get teachers => _text('teachers');
  String get rooms => _text('rooms');
  String get schedule => _text('schedule');
  String get notes => _text('notes');
  String get editNotes => _text('editNotes');
  String get homework => _text('homework');
  String get noSubjectTasks => _text('noSubjectTasks');
  String get deleteSubject => _text('deleteSubject');
  String deleteSubjectMessage(String value) =>
      _format('deleteSubjectMessage', value);
  String get dueOnNextClass => _text('dueOnNextClass');
  String notesFor(String courseCode) => _format('notesFor', courseCode);
  String get save => _text('save');
  String get newTask => _text('newTask');
  String get editTask => _text('editTask');
  String get taskTitle => _text('taskTitle');
  String get taskTitleRequired => _text('taskTitleRequired');
  String get subject => _text('subject');
  String get dueTime => _text('dueTime');
  String get priority => _text('priority');
  String get low => _text('low');
  String get normal => _text('normal');
  String get high => _text('high');
  String get reminder => _text('reminder');
  String get noReminder => _text('noReminder');
  String get changeReminderTime => _text('changeReminderTime');
  String get saveTask => _text('saveTask');
  String get keepMoving => _text('keepMoving');
  String tasksInView(int count, String state) =>
      _format('tasksInView', '$count|$state').replaceFirst('{state}', state);
  String get open => _text('open');
  String get all => _text('all');
  String get completed => _text('completed');
  String get anyPriority => _text('anyPriority');
  String get allSubjects => _text('allSubjects');
  String get noOpenTasks => _text('noOpenTasks');
  String get noMatchingTasks => _text('noMatchingTasks');
  String get unassigned => _text('unassigned');
  String get delete => _text('delete');
  String get deleteTask => _text('deleteTask');
  String deleteTaskMessage(String title) => _format('deleteTaskMessage', title);
  String get seminar => _text('seminar');
  String get mandatory => _text('mandatory');
  String get lecture => _text('lecture');
  String get recommended => _text('recommended');
  String get event => _text('event');
  String get addClass => _text('addClass');
  String get addClassTitle => _text('addClassTitle');
  String get classType => _text('classType');
  String get targetTimetable => _text('targetTimetable');
  String get createNewSubject => _text('createNewSubject');
  String get courseName => _text('courseName');
  String get courseNameRequired => _text('courseNameRequired');
  String get courseCodeOptional => _text('courseCodeOptional');
  String get seminarGroupOptional => _text('seminarGroupOptional');
  String get classDate => _text('classDate');
  String get startTime => _text('startTime');
  String get endTime => _text('endTime');
  String get invalidClassTime => _text('invalidClassTime');
  String get roomOptional => _text('roomOptional');
  String get teacherOptional => _text('teacherOptional');
  String get saveClass => _text('saveClass');
  String seminarDetails(String? group) =>
      group == null ? seminar : '$seminar $group';
  String get scheduledEvents => _text('scheduledEvents');
  String get preferences => _text('preferences');
  String get scheduleLabel => _text('scheduleLabel');
  String get at => _text('at');
  String get assignedTo => _text('assignedTo');
  String importFailed(String error) => _format('importFailed', error);
  String importSummary(int classes, int subjects, String semester) =>
      _text('importSummary')
          .replaceAll('{classes}', '$classes')
          .replaceAll('{subjects}', '$subjects')
          .replaceAll('{semester}', semester);
  String get week => _text('week');
  String get semester => _text('semester');
  String get tasks => _text('tasks');
  String get subjects => _text('subjects');
  String get settings => _text('settings');
  String get language => _text('language');
  String get languageSubtitle => _text('languageSubtitle');
  String get theme => _text('theme');
  String get themeSubtitle => _text('themeSubtitle');
  String get themeSystem => _text('themeSystem');
  String get themeLight => _text('themeLight');
  String get themeDark => _text('themeDark');
  String get general => _text('general');
  String get remindersEnabled => _text('remindersEnabled');
  String get remindersEnabledSubtitle => _text('remindersEnabledSubtitle');
  String get showRoomInSchedule => _text('showRoomInSchedule');
  String get showRoomInScheduleSubtitle => _text('showRoomInScheduleSubtitle');
  String get highlightCurrentDay => _text('highlightCurrentDay');
  String get highlightCurrentDaySubtitle =>
      _text('highlightCurrentDaySubtitle');
  String get classAppearance => _text('classAppearance');
  String get classAppearanceSubtitle => _text('classAppearanceSubtitle');
  String get lectureColor => _text('lectureColor');
  String get seminarColor => _text('seminarColor');
  String get personalPriority => _text('personalPriority');
  String get classColor => _text('classColor');
  String get useTypeColor => _text('useTypeColor');
  String get about => _text('about');
  String get aboutSubtitle => _text('aboutSubtitle');
  String get aboutPurposeTitle => _text('aboutPurposeTitle');
  String get aboutPurposeBody => _text('aboutPurposeBody');
  String get aboutPrivacyTitle => _text('aboutPrivacyTitle');
  String get aboutPrivacyBody => _text('aboutPrivacyBody');
  String get aboutIndependent => _text('aboutIndependent');
  String get madeBy => _text('madeBy');
  String get projectSource => _text('projectSource');
  String get projectSourceSubtitle => _text('projectSourceSubtitle');
  String get reportIssue => _text('reportIssue');
  String get reportIssueSubtitle => _text('reportIssueSubtitle');
  String get sendFeedback => _text('sendFeedback');
  String get sendFeedbackSubtitle => _text('sendFeedbackSubtitle');
  String get openSourceLicenses => _text('openSourceLicenses');
  String get openSourceLicensesSubtitle => _text('openSourceLicensesSubtitle');
  String get linkOpenFailed => _text('linkOpenFailed');
  String get easterEggTitle => _text('easterEggTitle');
  String get easterEggBody => _text('easterEggBody');
  String version(String value) => _format('version', value);
  String get manageTimetables => _text('manageTimetables');
  String get manageTimetablesSubtitle => _text('manageTimetablesSubtitle');
  String get importedTimetables => _text('importedTimetables');
  String get renameTimetable => _text('renameTimetable');
  String get renameTimetableTitle => _text('renameTimetableTitle');
  String get timetableName => _text('timetableName');
  String get timetableNameRequired => _text('timetableNameRequired');
  String get removeTimetables => _text('removeTimetables');
  String get removeTimetablesMessage => _text('removeTimetablesMessage');
  String get noImportedTimetables => _text('noImportedTimetables');
  String selectedTimetables(int count) =>
      _format('selectedTimetables', '$count');
  String get welcomeTitle => _text('welcomeTitle');
  String get welcomeDescription => _text('welcomeDescription');
  String get getStarted => _text('getStarted');
  String get back => _text('back');
  String get allFaculties => _text('allFaculties');
  String get filterFaculty => _text('filterFaculty');
  String get yourFaculties => _text('yourFaculties');
  String get importXml => _text('importXml');
  String get pasteXml => _text('pasteXml');
  String get pasteTimetableXml => _text('pasteTimetableXml');
  String get howToGetXml => _text('howToGetXml');
  String get howToGetXmlSteps => _text('howToGetXmlSteps');
  String get checkForUpdates => _text('checkForUpdates');
  String get checkingForUpdates => _text('checkingForUpdates');
  String get updateAvailable => _text('updateAvailable');
  String updateVersion(String version) =>
      _text('updateVersion').replaceFirst('{value}', version);
  String get updateNow => _text('updateNow');
  String get updateLater => _text('updateLater');
  String get updateDownloading => _text('updateDownloading');
  String get updateReady => _text('updateReady');
  String get updateInstall => _text('updateInstall');
  String get updatePermission => _text('updatePermission');
  String get updateCurrent => _text('updateCurrent');
  String get updateFailed => _text('updateFailed');
  String get cancel => _text('cancel');
  String get import => _text('import');
  String get continueLabel => _text('continue');
  String get whereStudying => _text('whereStudying');
  String get selectFaculties => _text('selectFaculties');
  String get saveFaculties => _text('saveFaculties');
  String get muniFaculty => _text('muniFaculty');
  String get chooseFaculty => _text('chooseFaculty');
  String get timetableImported => _text('timetableImported');
  String get timetableMerged => _text('timetableMerged');
  String get importDestination => _text('importDestination');
  String get importAsNewTimetable => _text('importAsNewTimetable');
  String get mergeWithTimetable => _text('mergeWithTimetable');
  String get timetableEmpty => _text('timetableEmpty');
  String get timetableEmptyDescription => _text('timetableEmptyDescription');
  String get noTimetableForFaculty => _text('noTimetableForFaculty');
  String get noTimetableForFacultyDescription =>
      _text('noTimetableForFacultyDescription');
  String get chooseDay => _text('chooseDay');
  String get timeline => _text('timeline');
  String get dueSoon => _text('dueSoon');
  String get noMoreClasses => _text('noMoreClasses');
  String get noClassesToday => _text('noClassesToday');
  String get nothingUrgent => _text('nothingUrgent');
  String get inProgress => _text('inProgress');
  String get upNext => _text('upNext');
  String endsIn(String duration) => _format('endsIn', duration);
  String startsIn(String duration) => _format('startsIn', duration);
  String classesToday(int count) => _format('classesToday', '$count');

  String _text(String key) =>
      _values[_languageCode]?[key] ?? _values['en']![key]!;
  String _format(String key, String value) {
    final parts = value.split('|');
    return _text(key)
        .replaceFirst('{value}', parts.first)
        .replaceFirst('{state}', parts.length > 1 ? parts[1] : '');
  }

  static const _values = <String, Map<String, String>>{
    'en': {
      'today': 'Today',
      'week': 'Week',
      'semester': 'Semester',
      'tasks': 'Tasks',
      'subjects': 'Subjects',
      'settings': 'Settings',
      'language': 'Language',
      'languageSubtitle': 'Choose the language used by the app.',
      'theme': 'Theme',
      'themeSubtitle': 'Choose how MUstr looks.',
      'themeSystem': 'System',
      'themeLight': 'Light',
      'themeDark': 'Dark',
      'general': 'GENERAL',
      'remindersEnabled': 'Homework reminders',
      'remindersEnabledSubtitle':
          'Get a notification when a reminder time you set is reached.',
      'showRoomInSchedule': 'Show room in schedule',
      'showRoomInScheduleSubtitle':
          'Display the classroom or location on schedule entries when there is space.',
      'highlightCurrentDay': 'Highlight today',
      'highlightCurrentDaySubtitle':
          'Tint the current day in the week timetable.',
      'classAppearance': 'CLASS APPEARANCE',
      'classAppearanceSubtitle':
          'Distinguish lectures and seminars across your timetable.',
      'lectureColor': 'Lecture color',
      'seminarColor': 'Seminar color',
      'personalPriority': 'Personal priority',
      'classColor': 'Class color',
      'useTypeColor': 'Use type color',
      'about': 'ABOUT',
      'aboutSubtitle': 'Your offline planner for Masaryk University.',
      'aboutPurposeTitle': 'Built for student life',
      'aboutPurposeBody':
          'MUstr turns exported MUNI timetables into a practical offline schedule with classes, tasks, exams, reminders, and a home-screen widget.',
      'aboutPrivacyTitle': 'Private by design',
      'aboutPrivacyBody':
          'Your timetable and study data stay on this device. MUstr only connects to GitHub when checking for app updates or when you open a project link.',
      'aboutIndependent':
          'MUstr is an independent student project and is not an official Masaryk University application.',
      'madeBy': 'Made by D4v31x',
      'projectSource': 'Source code',
      'projectSourceSubtitle': 'View the project on GitHub',
      'reportIssue': 'Report a problem',
      'reportIssueSubtitle': 'Open a bug report on GitHub',
      'sendFeedback': 'Share feedback or an idea',
      'sendFeedbackSubtitle': 'Suggest an improvement on GitHub',
      'openSourceLicenses': 'Open-source licenses',
      'openSourceLicensesSubtitle': 'Libraries and fonts used by MUstr',
      'linkOpenFailed': 'Could not open the link.',
      'easterEggTitle': 'Schedule diagnostics',
      'easterEggBody':
          'Seven taps detected. Unfortunately, no free Friday was found.',
      'version': 'Version {value}',
      'manageTimetables': 'TIMETABLES',
      'manageTimetablesSubtitle': 'Review or remove imported schedules.',
      'importedTimetables': 'Imported timetables',
      'renameTimetable': 'Rename',
      'renameTimetableTitle': 'Rename timetable',
      'timetableName': 'Timetable name',
      'timetableNameRequired': 'Enter a timetable name.',
      'removeTimetables': 'Remove timetables',
      'removeTimetablesMessage':
          'Remove the selected timetables and their classes? This cannot be undone.',
      'noImportedTimetables': 'No imported timetables.',
      'selectedTimetables': '{value} selected',
      'welcomeTitle': 'Your schedule in one place.',
      'welcomeDescription':
          'Keep your timetables, tasks, and deadlines together, even when you are offline.',
      'getStarted': 'Get started',
      'back': 'Back',
      'allFaculties': 'All faculties',
      'filterFaculty': 'Filter faculty',
      'yourFaculties': 'Your faculties',
      'importXml': 'Import XML',
      'pasteXml': 'Paste XML',
      'pasteTimetableXml': 'Paste timetable XML',
      'howToGetXml': 'How to retrieve the schedule XML?',
      'howToGetXmlSteps':
          '1. Open the MUNI Information System (IS MU) and go to the Schedule (Rozvrh) application.\n\n2. Click the settings button.\n\n3. Enable "Show teachers\' names".\n\n4. Set the view mode to "Programmer".\n\n5. Save - a page with the XML will appear.\n\n6. In your browser, choose "Save Page As..." and save it as XML.\n\n7. In your file manager, make sure the file has the .xml extension, then import it here.',
      'checkForUpdates': 'Check for updates',
      'checkingForUpdates': 'Checking for updates...',
      'updateAvailable': 'Update available',
      'updateVersion': 'MUstr {value} is ready to install.',
      'updateNow': 'Download update',
      'updateLater': 'Later',
      'updateDownloading': 'Downloading update...',
      'updateReady': 'The update is ready.',
      'updateInstall': 'Install',
      'updatePermission':
          'Allow MUstr to install unknown apps, then return and tap Install again.',
      'updateCurrent': 'MUstr is up to date.',
      'updateFailed': 'The update check failed.',
      'cancel': 'Cancel',
      'import': 'Import',
      'continue': 'Continue',
      'whereStudying': 'Where are you studying?',
      'selectFaculties':
          'Select every faculty you study at. You will assign each imported timetable to one of them.',
      'saveFaculties': 'Save faculties',
      'muniFaculty': 'MUNI faculty',
      'chooseFaculty': 'Assign timetable to faculty',
      'timetableImported': 'Timetable imported',
      'timetableMerged': 'Timetable merged',
      'importDestination': 'Where should the XML be imported?',
      'importAsNewTimetable': 'Create a new timetable',
      'mergeWithTimetable': 'Merge with an existing timetable',
      'timetableEmpty': 'Your timetable is empty',
      'timetableEmptyDescription':
          'Import your timetable from MUNI IS to get started.',
      'noTimetableForFaculty': 'No timetable for this faculty',
      'noTimetableForFacultyDescription':
          'Import an XML timetable and assign it here.',
      'chooseDay': 'Choose day',
      'timeline': 'Timeline',
      'dueSoon': 'Due soon',
      'noMoreClasses': 'No more classes today.',
      'noClassesToday': 'No classes are scheduled for today.',
      'nothingUrgent': 'Nothing urgent. Enjoy the clear runway.',
      'inProgress': 'In progress',
      'upNext': 'Up next',
      'endsIn': 'Ends in {value}',
      'startsIn': 'Starts in {value}',
      'classesToday': '{value} classes today',
      'weekOverview': 'WEEK OVERVIEW',
      'previousWeek': 'Previous week',
      'nextWeek': 'Next week',
      'semesterLabel': 'SEMESTER',
      'importedTimetable': 'Imported timetable',
      'addExam': 'Add exam',
      'examPeriod': 'Exam period',
      'exam': 'Exam',
      'jumpToWeek': 'Jump to week',
      'scheduledEvents': 'scheduled events',
      'deadlines': 'Deadlines',
      'assessments': 'Assessments',
      'noDeadlines': 'No open deadlines in this week.',
      'noExams': 'No upcoming exams added yet.',
      'independentExam': 'Independent exam',
      'deleteExam': 'Delete exam',
      'addExamTitle': 'Add exam',
      'examTitle': 'Exam title',
      'examTitleRequired': 'An exam title is required.',
      'faculty': 'Faculty',
      'subjectOptional': 'Subject (optional)',
      'noSubject': 'No subject',
      'roomOrOnlineLocation': 'Room or online location (optional)',
      'notesOptional': 'Notes (optional)',
      'saveExam': 'Save exam',
      'starts': 'Starts',
      'ends': 'Ends',
      'saveExamPeriod': 'Save exam period',
      'invalidExamPeriod': 'The end date must be after the start date.',
      'yourCourses': 'YOUR COURSES',
      'subjectsInTimetable': '{value} subjects in this timetable',
      'scheduledClasses': '{value} scheduled classes',
      'teachers': 'Teachers',
      'rooms': 'Rooms',
      'schedule': 'Schedule',
      'notes': 'Notes',
      'editNotes': 'Edit notes',
      'homework': 'Homework',
      'noSubjectTasks': 'No tasks assigned to this subject.',
      'deleteSubject': 'Delete subject',
      'deleteSubjectMessage':
          'Delete "{value}" and all of its scheduled classes? Homework and exams will remain unassigned.',
      'dueOnNextClass': 'Due on next class',
      'notesFor': 'Notes for {value}',
      'save': 'Save',
      'newTask': 'New task',
      'editTask': 'Edit task',
      'taskTitle': 'Title',
      'taskTitleRequired': 'A title is required.',
      'subject': 'Subject',
      'dueTime': 'Due time',
      'priority': 'Priority',
      'low': 'Low',
      'normal': 'Normal',
      'high': 'High',
      'reminder': 'Reminder',
      'noReminder': 'No reminder',
      'changeReminderTime': 'Change reminder time',
      'saveTask': 'Save task',
      'keepMoving': 'Keep moving',
      'tasksInView': '{value} {state} tasks in view',
      'open': 'Open',
      'all': 'All',
      'completed': 'Completed',
      'anyPriority': 'Any priority',
      'allSubjects': 'All subjects',
      'noOpenTasks': 'Nothing is waiting on you.',
      'noMatchingTasks': 'No tasks match these filters.',
      'unassigned': 'Unassigned',
      'delete': 'Delete',
      'deleteTask': 'Delete task?',
      'deleteTaskMessage': 'Delete "{value}" permanently?',
      'seminar': 'Seminar',
      'mandatory': 'Mandatory',
      'lecture': 'Lecture',
      'recommended': 'Recommended',
      'event': 'Event',
      'addClass': 'Add class',
      'addClassTitle': 'Add to schedule',
      'classType': 'Class type',
      'targetTimetable': 'Timetable',
      'createNewSubject': 'Create new subject',
      'courseName': 'Course name',
      'courseNameRequired': 'Enter a course name.',
      'courseCodeOptional': 'Course code (optional)',
      'seminarGroupOptional': 'Seminar group (optional)',
      'classDate': 'Date',
      'startTime': 'Start time',
      'endTime': 'End time',
      'invalidClassTime': 'The end time must be after the start time.',
      'roomOptional': 'Room (optional)',
      'teacherOptional': 'Teacher (optional)',
      'saveClass': 'Add class',
      'preferences': 'PREFERENCES',
      'scheduleLabel': 'SCHEDULE',
      'at': 'at',
      'assignedTo': 'Assigned to',
      'importFailed': 'Could not import XML: {value}',
      'importSummary': '{classes} classes\n{subjects} subjects\n{semester}',
    },
    'cs': {
      'today': 'Dnes',
      'week': 'Týden',
      'semester': 'Semestr',
      'tasks': 'Úkoly',
      'subjects': 'Předměty',
      'settings': 'Nastavení',
      'language': 'Jazyk',
      'languageSubtitle': 'Vyberte jazyk používaný aplikací.',
      'theme': 'Vzhled',
      'themeSubtitle': 'Vyberte, jak MUstr vypadá.',
      'themeSystem': 'Podle systému',
      'themeLight': 'Světlý',
      'themeDark': 'Tmavý',
      'general': 'OBECNÉ',
      'remindersEnabled': 'Připomínky úkolů',
      'remindersEnabledSubtitle':
          'Dostanete upozornění, když nastane nastavený čas připomínky.',
      'showRoomInSchedule': 'Zobrazovat místnost v rozvrhu',
      'showRoomInScheduleSubtitle':
          'Zobrazit učebnu nebo místo výuky v rozvrhu, pokud je místo.',
      'highlightCurrentDay': 'Zvýraznit dnešní den',
      'highlightCurrentDaySubtitle':
          'Zvýraznit aktuální den v týdenním rozvrhu.',
      'classAppearance': 'VZHLED VÝUKY',
      'classAppearanceSubtitle':
          'Rozlište přednášky a semináře v celém rozvrhu.',
      'lectureColor': 'Barva přednášky',
      'seminarColor': 'Barva semináře',
      'personalPriority': 'Osobní priorita',
      'classColor': 'Barva výuky',
      'useTypeColor': 'Použít barvu typu',
      'about': 'O APLIKACI',
      'aboutSubtitle': 'Váš offline plánovač pro Masarykovu univerzitu.',
      'aboutPurposeTitle': 'Pro každodenní studentský život',
      'aboutPurposeBody':
          'MUstr promění exportovaný rozvrh MU v praktický offline plánovač s výukou, úkoly, zkouškami, připomínkami a widgetem na plochu.',
      'aboutPrivacyTitle': 'Soukromí na prvním místě',
      'aboutPrivacyBody':
          'Rozvrh a studijní data zůstávají v tomto zařízení. MUstr se připojuje ke GitHubu pouze při kontrole aktualizací nebo otevření odkazu projektu.',
      'aboutIndependent':
          'MUstr je nezávislý studentský projekt a není oficiální aplikací Masarykovy univerzity.',
      'madeBy': 'Vytvořil D4v31x',
      'projectSource': 'Zdrojový kód',
      'projectSourceSubtitle': 'Zobrazit projekt na GitHubu',
      'reportIssue': 'Nahlásit problém',
      'reportIssueSubtitle': 'Vytvořit hlášení chyby na GitHubu',
      'sendFeedback': 'Poslat zpětnou vazbu nebo nápad',
      'sendFeedbackSubtitle': 'Navrhnout vylepšení na GitHubu',
      'openSourceLicenses': 'Open-source licence',
      'openSourceLicensesSubtitle': 'Knihovny a písma použité v MUstr',
      'linkOpenFailed': 'Odkaz se nepodařilo otevřít.',
      'easterEggTitle': 'Diagnostika rozvrhu',
      'easterEggBody':
          'Zjištěno sedm klepnutí. Volný pátek se bohužel nenašel.',
      'version': 'Verze {value}',
      'manageTimetables': 'ROZVRHY',
      'manageTimetablesSubtitle':
          'Zkontrolujte nebo odeberte importované rozvrhy.',
      'importedTimetables': 'Importované rozvrhy',
      'renameTimetable': 'Přejmenovat',
      'renameTimetableTitle': 'Přejmenovat rozvrh',
      'timetableName': 'Název rozvrhu',
      'timetableNameRequired': 'Zadejte název rozvrhu.',
      'removeTimetables': 'Odebrat rozvrhy',
      'removeTimetablesMessage':
          'Odebrat vybrané rozvrhy a jejich výuky? Tuto akci nelze vrátit zpět.',
      'noImportedTimetables': 'Žádné importované rozvrhy.',
      'selectedTimetables': 'Vybráno: {value}',
      'welcomeTitle': 'Váš rozvrh na jednom místě.',
      'welcomeDescription':
          'Mějte rozvrhy, úkoly a termíny pohromadě, i když jste offline.',
      'getStarted': 'Začít',
      'back': 'Zpět',
      'allFaculties': 'Všechny fakulty',
      'filterFaculty': 'Filtrovat fakultu',
      'yourFaculties': 'Vaše fakulty',
      'importXml': 'Importovat XML',
      'pasteXml': 'Vložit XML',
      'pasteTimetableXml': 'Vložit XML rozvrhu',
      'howToGetXml': 'Jak získat XML rozvrhu?',
      'howToGetXmlSteps':
          '1. Otevřete Informační systém MU (IS MU) a přejděte do aplikace Rozvrh.\n\n2. Klikněte na tlačítko nastavení.\n\n3. Zaškrtněte možnost „Zobrazit jména vyučujících“.\n\n4. Nastavte zobrazení jako „Programátor“.\n\n5. Uložte – zobrazí se stránka s XML.\n\n6. V prohlížeči zvolte „Uložit stránku jako...“ a uložte ji jako XML.\n\n7. Ve správci souborů zkontrolujte, že soubor má příponu .xml, a poté ho zde importujte.',
      'checkForUpdates': 'Zkontrolovat aktualizace',
      'checkingForUpdates': 'Kontrola aktualizací...',
      'updateAvailable': 'Je dostupná aktualizace',
      'updateVersion': 'MUstr {value} je připraven k instalaci.',
      'updateNow': 'Stáhnout aktualizaci',
      'updateLater': 'Později',
      'updateDownloading': 'Stahování aktualizace...',
      'updateReady': 'Aktualizace je připravena.',
      'updateInstall': 'Nainstalovat',
      'updatePermission':
          'Povolte aplikaci MUstr instalovat neznámé aplikace, potom se vraťte a znovu klepněte na Nainstalovat.',
      'updateCurrent': 'Aplikace MUstr je aktuální.',
      'updateFailed': 'Kontrola aktualizací se nezdařila.',
      'cancel': 'Zrušit',
      'import': 'Importovat',
      'continue': 'Pokračovat',
      'whereStudying': 'Kde studujete?',
      'selectFaculties':
          'Vyberte všechny fakulty, na kterých studujete. Každý importovaný rozvrh přiřadíte k jedné z nich.',
      'saveFaculties': 'Uložit fakulty',
      'muniFaculty': 'Fakulta MU',
      'chooseFaculty': 'Přiřadit rozvrh k fakultě',
      'timetableImported': 'Rozvrh importován',
      'timetableMerged': 'Rozvrhy byly sloučeny',
      'importDestination': 'Kam chcete XML importovat?',
      'importAsNewTimetable': 'Vytvořit nový rozvrh',
      'mergeWithTimetable': 'Sloučit s existujícím rozvrhem',
      'timetableEmpty': 'Váš rozvrh je prázdný',
      'timetableEmptyDescription': 'Začněte importem rozvrhu z IS MU.',
      'noTimetableForFaculty': 'Pro tuto fakultu není rozvrh',
      'noTimetableForFacultyDescription':
          'Importujte XML rozvrhu a přiřaďte ho sem.',
      'chooseDay': 'Vybrat den',
      'timeline': 'Harmonogram',
      'dueSoon': 'Brzké termíny',
      'noMoreClasses': 'Dnes už žádnou další výuku nemáte.',
      'noClassesToday': 'Na dnes není naplánovaná žádná výuka.',
      'nothingUrgent': 'Nic nehoří. Užijte si volný čas.',
      'inProgress': 'Právě probíhá',
      'upNext': 'Následuje',
      'endsIn': 'Končí za {value}',
      'startsIn': 'Začíná za {value}',
      'classesToday': 'Dnes {value} výuk',
      'weekOverview': 'PŘEHLED TÝDNE',
      'previousWeek': 'Předchozí týden',
      'nextWeek': 'Další týden',
      'semesterLabel': 'SEMESTR',
      'importedTimetable': 'Importovaný rozvrh',
      'addExam': 'Přidat zkoušku',
      'examPeriod': 'Zkouškové období',
      'exam': 'Zkouška',
      'jumpToWeek': 'Přejít na týden',
      'scheduledEvents': 'naplánovaných akcí',
      'deadlines': 'Termíny',
      'assessments': 'Hodnocení',
      'noDeadlines': 'V tomto týdnu nejsou žádné otevřené termíny.',
      'noExams': 'Zatím nejsou přidané žádné nadcházející zkoušky.',
      'independentExam': 'Samostatná zkouška',
      'deleteExam': 'Smazat zkoušku',
      'addExamTitle': 'Přidat zkoušku',
      'examTitle': 'Název zkoušky',
      'examTitleRequired': 'Název zkoušky je povinný.',
      'faculty': 'Fakulta',
      'subjectOptional': 'Předmět (volitelné)',
      'noSubject': 'Bez předmětu',
      'roomOrOnlineLocation': 'Místnost nebo online místo (volitelné)',
      'notesOptional': 'Poznámky (volitelné)',
      'saveExam': 'Uložit zkoušku',
      'starts': 'Začíná',
      'ends': 'Končí',
      'saveExamPeriod': 'Uložit zkouškové období',
      'invalidExamPeriod': 'Datum konce musí být po datu začátku.',
      'yourCourses': 'VAŠE PŘEDMĚTY',
      'subjectsInTimetable': '{value} předmětů v tomto rozvrhu',
      'scheduledClasses': '{value} naplánovaných výuk',
      'teachers': 'Vyučující',
      'rooms': 'Místnosti',
      'schedule': 'Rozvrh',
      'notes': 'Poznámky',
      'editNotes': 'Upravit poznámky',
      'homework': 'Úkoly',
      'noSubjectTasks': 'K tomuto předmětu nejsou přiřazené žádné úkoly.',
      'deleteSubject': 'Smazat předmět',
      'deleteSubjectMessage':
          'Smazat „{value}“ a všechny jeho naplánované výuky? Úkoly a zkoušky zůstanou bez přiřazení.',
      'dueOnNextClass': 'Termín při příští výuce',
      'notesFor': 'Poznámky k {value}',
      'save': 'Uložit',
      'newTask': 'Nový úkol',
      'editTask': 'Upravit úkol',
      'taskTitle': 'Název',
      'taskTitleRequired': 'Název je povinný.',
      'subject': 'Předmět',
      'dueTime': 'Čas termínu',
      'priority': 'Priorita',
      'low': 'Nízká',
      'normal': 'Běžná',
      'high': 'Vysoká',
      'reminder': 'Připomínka',
      'noReminder': 'Bez připomínky',
      'changeReminderTime': 'Změnit čas připomínky',
      'saveTask': 'Uložit úkol',
      'keepMoving': 'Vše pod kontrolou',
      'tasksInView': 'Zobrazeno úkolů: {value} ({state})',
      'open': 'Otevřené',
      'all': 'Vše',
      'completed': 'Dokončené',
      'anyPriority': 'Libovolná priorita',
      'allSubjects': 'Všechny předměty',
      'noOpenTasks': 'Nic na vás nečeká.',
      'noMatchingTasks': 'Žádné úkoly neodpovídají filtrům.',
      'unassigned': 'Nepřiřazeno',
      'delete': 'Smazat',
      'deleteTask': 'Smazat úkol?',
      'deleteTaskMessage': 'Opravdu trvale smazat „{value}“?',
      'seminar': 'Seminář',
      'mandatory': 'Povinný',
      'lecture': 'Přednáška',
      'recommended': 'Doporučená',
      'event': 'Akce',
      'addClass': 'Přidat výuku',
      'addClassTitle': 'Přidat do rozvrhu',
      'classType': 'Typ výuky',
      'targetTimetable': 'Rozvrh',
      'createNewSubject': 'Vytvořit nový předmět',
      'courseName': 'Název předmětu',
      'courseNameRequired': 'Zadejte název předmětu.',
      'courseCodeOptional': 'Kód předmětu (volitelné)',
      'seminarGroupOptional': 'Seminární skupina (volitelné)',
      'classDate': 'Datum',
      'startTime': 'Začátek',
      'endTime': 'Konec',
      'invalidClassTime': 'Čas konce musí být po čase začátku.',
      'roomOptional': 'Místnost (volitelné)',
      'teacherOptional': 'Vyučující (volitelné)',
      'saveClass': 'Přidat výuku',
      'preferences': 'PŘEDVOLBY',
      'scheduleLabel': 'ROZVRH',
      'at': 'v',
      'assignedTo': 'Přiřazeno k',
      'importFailed': 'XML se nepodařilo importovat: {value}',
      'importSummary': '{classes} výuk\n{subjects} předmětů\n{semester}',
    },
    'sk': {
      'today': 'Dnes',
      'week': 'Týždeň',
      'semester': 'Semester',
      'tasks': 'Úlohy',
      'subjects': 'Predmety',
      'settings': 'Nastavenia',
      'language': 'Jazyk',
      'languageSubtitle': 'Vyberte jazyk používaný aplikáciou.',
      'theme': 'Vzhľad',
      'themeSubtitle': 'Vyberte, ako MUstr vyzerá.',
      'themeSystem': 'Podľa systému',
      'themeLight': 'Svetlý',
      'themeDark': 'Tmavý',
      'general': 'VŠEOBECNÉ',
      'remindersEnabled': 'Pripomienky úlohy',
      'remindersEnabledSubtitle':
          'Dostanete upozornenie, keď nastane nastavený čas pripomienky.',
      'showRoomInSchedule': 'Zobrazovať miestnosť v rozvrhu',
      'showRoomInScheduleSubtitle':
          'Zobraziť učebňu alebo miesto výučby v rozvrhu, ak je miesto.',
      'highlightCurrentDay': 'Zvýrazniť dnešný deň',
      'highlightCurrentDaySubtitle':
          'Zvýrazniť aktuálny deň v týždennom rozvrhu.',
      'classAppearance': 'VZHĽAD VÝUČBY',
      'classAppearanceSubtitle':
          'Rozlíšte prednášky a semináre v celom rozvrhu.',
      'lectureColor': 'Farba prednášky',
      'seminarColor': 'Farba seminára',
      'personalPriority': 'Osobná priorita',
      'classColor': 'Farba výučby',
      'useTypeColor': 'Použiť farbu typu',
      'about': 'O APLIKÁCII',
      'aboutSubtitle': 'Váš offline plánovač pre Masarykovu univerzitu.',
      'aboutPurposeTitle': 'Pre každodenný študentský život',
      'aboutPurposeBody':
          'MUstr premení exportovaný rozvrh MU na praktický offline plánovač s výučbou, úlohami, skúškami, pripomienkami a widgetom na plochu.',
      'aboutPrivacyTitle': 'Súkromie na prvom mieste',
      'aboutPrivacyBody':
          'Rozvrh a študijné údaje zostávajú v tomto zariadení. MUstr sa pripája ku GitHubu iba pri kontrole aktualizácií alebo otvorení odkazu projektu.',
      'aboutIndependent':
          'MUstr je nezávislý študentský projekt a nie je oficiálnou aplikáciou Masarykovej univerzity.',
      'madeBy': 'Vytvoril D4v31x',
      'projectSource': 'Zdrojový kód',
      'projectSourceSubtitle': 'Zobraziť projekt na GitHube',
      'reportIssue': 'Nahlásiť problém',
      'reportIssueSubtitle': 'Vytvoriť hlásenie chyby na GitHube',
      'sendFeedback': 'Poslať spätnú väzbu alebo nápad',
      'sendFeedbackSubtitle': 'Navrhnúť vylepšenie na GitHube',
      'openSourceLicenses': 'Open-source licencie',
      'openSourceLicensesSubtitle': 'Knižnice a písma použité v MUstr',
      'linkOpenFailed': 'Odkaz sa nepodarilo otvoriť.',
      'easterEggTitle': 'Diagnostika rozvrhu',
      'easterEggBody':
          'Zistených sedem ťuknutí. Voľný piatok sa, žiaľ, nenašiel.',
      'version': 'Verzia {value}',
      'manageTimetables': 'ROZVRHY',
      'manageTimetablesSubtitle':
          'Skontrolujte alebo odstráňte importované rozvrhy.',
      'importedTimetables': 'Importované rozvrhy',
      'renameTimetable': 'Premenovať',
      'renameTimetableTitle': 'Premenovať rozvrh',
      'timetableName': 'Názov rozvrhu',
      'timetableNameRequired': 'Zadajte názov rozvrhu.',
      'removeTimetables': 'Odstrániť rozvrhy',
      'removeTimetablesMessage':
          'Odstrániť vybrané rozvrhy a ich výučby? Túto akciu nemožno vrátiť späť.',
      'noImportedTimetables': 'Žiadne importované rozvrhy.',
      'selectedTimetables': 'Vybrané: {value}',
      'welcomeTitle': 'Váš rozvrh na jednom mieste.',
      'welcomeDescription':
          'Majte rozvrhy, úlohy a termíny pohromade, aj keď ste offline.',
      'getStarted': 'Začať',
      'back': 'Späť',
      'allFaculties': 'Všetky fakulty',
      'filterFaculty': 'Filtrovať fakultu',
      'yourFaculties': 'Vaše fakulty',
      'importXml': 'Importovať XML',
      'pasteXml': 'Vložiť XML',
      'pasteTimetableXml': 'Vložiť XML rozvrhu',
      'howToGetXml': 'Ako získať XML rozvrhu?',
      'howToGetXmlSteps':
          '1. Otvorte Informačný systém MU (IS MU) a prejdite do aplikácie Rozvrh.\n\n2. Kliknite na tlačidlo nastavenia.\n\n3. Zaškrtnite možnosť „Zobraziť mená vyučujúcich“.\n\n4. Nastavte zobrazenie ako „Programátor“.\n\n5. Uložte – zobrazí sa stránka s XML.\n\n6. V prehliadači zvoľte „Uložiť stránku ako...“ a uložte ju ako XML.\n\n7. V správcovi súborov skontrolujte, že súbor má príponu .xml, a potom ho tu importujte.',
      'checkForUpdates': 'Skontrolovať aktualizácie',
      'checkingForUpdates': 'Kontrola aktualizácií...',
      'updateAvailable': 'Je dostupná aktualizácia',
      'updateVersion': 'MUstr {value} je pripravený na inštaláciu.',
      'updateNow': 'Stiahnuť aktualizáciu',
      'updateLater': 'Neskôr',
      'updateDownloading': 'Sťahovanie aktualizácie...',
      'updateReady': 'Aktualizácia je pripravená.',
      'updateInstall': 'Nainštalovať',
      'updatePermission':
          'Povoľte aplikácii MUstr inštalovať neznáme aplikácie, potom sa vráťte a znova ťuknite na Nainštalovať.',
      'updateCurrent': 'Aplikácia MUstr je aktuálna.',
      'updateFailed': 'Kontrola aktualizácií zlyhala.',
      'cancel': 'Zrušiť',
      'import': 'Importovať',
      'continue': 'Pokračovať',
      'whereStudying': 'Kde študujete?',
      'selectFaculties':
          'Vyberte všetky fakulty, na ktorých študujete. Každý importovaný rozvrh priradíte k jednej z nich.',
      'saveFaculties': 'Uložiť fakulty',
      'muniFaculty': 'Fakulta MU',
      'chooseFaculty': 'Priradiť rozvrh k fakulte',
      'timetableImported': 'Rozvrh importovaný',
      'timetableMerged': 'Rozvrhy boli zlúčené',
      'importDestination': 'Kam chcete XML importovať?',
      'importAsNewTimetable': 'Vytvoriť nový rozvrh',
      'mergeWithTimetable': 'Zlúčiť s existujúcim rozvrhom',
      'timetableEmpty': 'Váš rozvrh je prázdny',
      'timetableEmptyDescription': 'Začnite importom rozvrhu z IS MU.',
      'noTimetableForFaculty': 'Pre túto fakultu nie je rozvrh',
      'noTimetableForFacultyDescription':
          'Importujte XML rozvrhu a priraďte ho sem.',
      'chooseDay': 'Vybrať deň',
      'timeline': 'Harmonogram',
      'dueSoon': 'Blízke termíny',
      'noMoreClasses': 'Dnes už nemáte ďalšiu výučbu.',
      'noClassesToday': 'Na dnes nie je naplánovaná žiadna výučba.',
      'nothingUrgent': 'Nič súrne. Užite si voľný priestor.',
      'inProgress': 'Prebieha',
      'upNext': 'Nasleduje',
      'endsIn': 'Končí o {value}',
      'startsIn': 'Začína o {value}',
      'classesToday': 'Dnes {value} výučby',
      'weekOverview': 'PREHĽAD TÝŽDŇA',
      'previousWeek': 'Predchádzajúci týždeň',
      'nextWeek': 'Nasledujúci týždeň',
      'semesterLabel': 'SEMESTER',
      'importedTimetable': 'Importovaný rozvrh',
      'addExam': 'Pridať skúšku',
      'examPeriod': 'Skúškové obdobie',
      'exam': 'Skúška',
      'jumpToWeek': 'Prejsť na týždeň',
      'scheduledEvents': 'naplánovaných udalostí',
      'deadlines': 'Termíny',
      'assessments': 'Hodnotenia',
      'noDeadlines': 'V tomto týždni nie sú žiadne otvorené termíny.',
      'noExams': 'Zatiaľ nie sú pridané žiadne nadchádzajúce skúšky.',
      'independentExam': 'Samostatná skúška',
      'deleteExam': 'Vymazať skúšku',
      'addExamTitle': 'Pridať skúšku',
      'examTitle': 'Názov skúšky',
      'examTitleRequired': 'Názov skúšky je povinný.',
      'faculty': 'Fakulta',
      'subjectOptional': 'Predmet (voliteľné)',
      'noSubject': 'Bez predmetu',
      'roomOrOnlineLocation': 'Miestnosť alebo online miesto (voliteľné)',
      'notesOptional': 'Poznámky (voliteľné)',
      'saveExam': 'Uložiť skúšku',
      'starts': 'Začína',
      'ends': 'Končí',
      'saveExamPeriod': 'Uložiť skúškové obdobie',
      'invalidExamPeriod': 'Dátum konca musí byť po dátume začiatku.',
      'yourCourses': 'VAŠE PREDMETY',
      'subjectsInTimetable': '{value} predmetov v tomto rozvrhu',
      'scheduledClasses': '{value} naplánovaných výučieb',
      'teachers': 'Vyučujúci',
      'rooms': 'Miestnosti',
      'schedule': 'Rozvrh',
      'notes': 'Poznámky',
      'editNotes': 'Upraviť poznámky',
      'homework': 'Úlohy',
      'noSubjectTasks': 'K tomuto predmetu nie sú priradené žiadne úlohy.',
      'deleteSubject': 'Vymazať predmet',
      'deleteSubjectMessage':
          'Vymazať „{value}“ a všetky jeho naplánované výučby? Úlohy a skúšky zostanú nepriradené.',
      'dueOnNextClass': 'Termín na ďalšej výučbe',
      'notesFor': 'Poznámky k {value}',
      'save': 'Uložiť',
      'newTask': 'Nová úloha',
      'editTask': 'Upraviť úlohu',
      'taskTitle': 'Názov',
      'taskTitleRequired': 'Názov je povinný.',
      'subject': 'Predmet',
      'dueTime': 'Čas termínu',
      'priority': 'Priorita',
      'low': 'Nízka',
      'normal': 'Bežná',
      'high': 'Vysoká',
      'reminder': 'Pripomienka',
      'noReminder': 'Bez pripomienky',
      'changeReminderTime': 'Zmeniť čas pripomienky',
      'saveTask': 'Uložiť úlohu',
      'keepMoving': 'Všetko pod kontrolou',
      'tasksInView': 'Zobrazené úlohy: {value} ({state})',
      'open': 'Otvorené',
      'all': 'Všetko',
      'completed': 'Dokončené',
      'anyPriority': 'Ľubovoľná priorita',
      'allSubjects': 'Všetky predmety',
      'noOpenTasks': 'Nič na vás nečaká.',
      'noMatchingTasks': 'Žiadne úlohy nezodpovedajú filtrům.',
      'unassigned': 'Nepriradené',
      'delete': 'Vymazať',
      'deleteTask': 'Vymazať úlohu?',
      'deleteTaskMessage': 'Naozaj natrvalo vymazať „{value}“?',
      'seminar': 'Seminár',
      'mandatory': 'Povinný',
      'lecture': 'Prednáška',
      'recommended': 'Odporúčaná',
      'event': 'Udalosť',
      'addClass': 'Pridať výučbu',
      'addClassTitle': 'Pridať do rozvrhu',
      'classType': 'Typ výučby',
      'targetTimetable': 'Rozvrh',
      'createNewSubject': 'Vytvoriť nový predmet',
      'courseName': 'Názov predmetu',
      'courseNameRequired': 'Zadajte názov predmetu.',
      'courseCodeOptional': 'Kód predmetu (voliteľné)',
      'seminarGroupOptional': 'Seminárna skupina (voliteľné)',
      'classDate': 'Dátum',
      'startTime': 'Začiatok',
      'endTime': 'Koniec',
      'invalidClassTime': 'Čas konca musí byť po čase začiatku.',
      'roomOptional': 'Miestnosť (voliteľné)',
      'teacherOptional': 'Vyučujúci (voliteľné)',
      'saveClass': 'Pridať výučbu',
      'preferences': 'PREDVOĽBY',
      'scheduleLabel': 'ROZVRH',
      'at': 'o',
      'assignedTo': 'Priradené k',
      'importFailed': 'XML sa nepodarilo importovať: {value}',
      'importSummary': '{classes} výučieb\n{subjects} predmetov\n{semester}',
    },
  };
}

extension AppStringsContext on BuildContext {
  AppStrings get strings => AppStrings.of(this);
}
