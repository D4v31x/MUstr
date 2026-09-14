<p align="center">
	<img src="assets/MUNI_Time_icon.png" width="144" alt="MUstr calendar logo">
</p>

<h1 align="center">MUstr</h1>

<p align="center">
	An offline schedule viewer and companion for MUNI students, made in Flutter.
</p>

<p align="center">
	<a href="https://github.com/D4v31x/MUstr/releases/latest">Download for Android</a>
	&nbsp;|&nbsp;
	<a href="https://github.com/D4v31x/MUstr/issues">Report an issue</a>
	&nbsp;|&nbsp;
	<a href="LICENSE">Apache-2.0</a>
</p>

MUstr turns an exported MUNI timetable into a clear, personal schedule you can use without a permanent internet connection. It is designed for quickly checking what is next, browsing your week, keeping course information together, and not missing dates that matter during the semester.

> MUstr is an independent student project. It is not an official Masaryk University application.

## Features

- **Today at a glance**: See current and upcoming classes, room details, and a chronological daily timeline. Classes disappear automatically after they end.
- **Weekly timetable**: Browse an interactive week view with lecture, seminar, exam, and important-date colors. Dense overlaps are grouped into an expandable stack.
- **Semester overview**: Keep semester start/end dates, exam periods, exams, and important milestones in one place. Tap an item to view or edit its details.
- **Important dates**: Add course registration, enrollment changes, tuition deadlines, holidays, or any other key date. Dates can have an optional time, faculty scope, and reminder.
- **Tasks and courses**: Attach homework, notes, and reminders to imported subjects.
- **Multiple faculties and schedules**: Import more than one timetable, filter by faculty, or merge an updated XML export into an existing schedule.
- **Manual classes**: Add a lecture, seminar, or event that is missing from an XML export.
- **Class preferences and reminders**: Set a priority, a personal color, or a reminder for an individual class occurrence.
- **Home-screen widget**: Keep your selected schedule visible from the Android home screen. It includes exams and important dates and automatically omits finished classes.
- **Your language and appearance**: Available in English, Czech, and Slovak, with system, light, and dark modes. Use Material You colors from your device or choose a MUstr palette.
- **Safer changes**: Confirm before deleting schedule data or saving edits to an existing item.
- **In-app updates**: Check and install new Android releases from GitHub when available.

## Get MUstr

1. Open the [latest release](https://github.com/D4v31x/MUstr/releases/latest) on your Android device.
2. Download the `MUstr-<version>.apk` file.
3. Open the downloaded APK and allow installation from your browser or file manager when Android asks.
4. Open MUstr and select your faculty or faculties.

MUstr can also download future releases from the in-app **Check for updates** screen. Android will always ask for confirmation before installing an update.

## Import Your Schedule

1. In MUNI IS, export your timetable as an XML file.
2. In MUstr, choose **Import XML** from the menu.
3. Select the XML file and assign it to the appropriate faculty.
4. When importing an updated export, choose whether to create a new timetable or merge it into the existing one.

The imported schedule is stored on your device. The app continues to work offline after the import.

## Important Dates and Reminders

Open the **Semester** tab to add the milestones around your schedule:

- Add **exam periods** for each faculty.
- Add individual **exams**, with a subject, date, time, location, and notes.
- Add **important dates** such as registration opening, enrollment deadlines, or holidays.
- Choose an optional time and a reminder for each important date. Timed dates also appear in the Today timeline.
- Tap an existing item to review its details or make an edit. MUstr asks for confirmation before applying an edit or deleting an item.

Notifications require Android notification permission. MUstr only schedules reminders that you explicitly create, including optional reminders for individual class occurrences, and keeps them on the device.

## Home-Screen Widget

Add the MUstr widget from your Android launcher's widget picker, then choose the timetable it should show. The widget groups classes, exams, and important dates by day, reflects the language and schedule data currently stored in MUstr, and hides classes once they have ended.

## Privacy

Your imported schedules, tasks, notes, exams, and important dates are stored locally on your device. MUstr uses the internet when you choose to check for or download an app update.

Analytics are off by default. When you explicitly opt in during onboarding or in Settings, MUstr creates a random app-install ID and sends it, your selected faculty IDs, and anonymous usage data to PostHog. You can withdraw consent in Settings at any time; MUstr then disables collection and clears the local PostHog identity. MUstr does not require a MUNI account password and does not upload your schedule to a MUstr server.

## Screenshots

<img width="1440" height="3120" alt="Screenshot_20260914_001246" src="https://github.com/user-attachments/assets/7d8eaad1-edb0-4b19-86ce-66158c58f2d2" />

<img width="1440" height="3120" alt="Screenshot_20260914_001341" src="https://github.com/user-attachments/assets/e334491b-39bc-4af5-a0d6-bf89166544c0" />

<img width="1440" height="3120" alt="Screenshot_20260914_001550" src="https://github.com/user-attachments/assets/bef78748-d9c0-4238-b253-bc0f94f0645f" />

## Support and Feedback

- [Report a bug](https://github.com/D4v31x/MUstr/issues/new?labels=bug&title=Bug%3A%20)
- [Suggest an improvement](https://github.com/D4v31x/MUstr/issues/new?labels=feedback&title=Feedback%3A%20)
- [Browse the source code](https://github.com/D4v31x/MUstr)

## License

MUstr is licensed under the [Apache License 2.0](LICENSE).
