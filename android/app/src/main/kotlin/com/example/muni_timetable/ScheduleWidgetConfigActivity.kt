package com.example.muni_timetable

import android.app.Activity
import android.appwidget.AppWidgetManager
import android.content.Intent
import android.content.res.ColorStateList
import android.os.Bundle
import android.view.Gravity
import android.view.ViewGroup
import android.widget.Button
import android.widget.CheckBox
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast
import androidx.core.content.ContextCompat
import es.antonborri.home_widget.HomeWidgetPlugin

class ScheduleWidgetConfigActivity : Activity() {
    private var appWidgetId = AppWidgetManager.INVALID_APPWIDGET_ID
    private val checkboxes = mutableListOf<CheckBox>()
    private lateinit var localized: android.content.Context

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setResult(RESULT_CANCELED)

        appWidgetId = intent?.extras?.getInt(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID,
        ) ?: AppWidgetManager.INVALID_APPWIDGET_ID
        if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) {
            finish()
            return
        }

        val appLanguage = HomeWidgetPlugin.getData(this).getString("app_language", null)
        localized = localizedScheduleContext(this, appLanguage)

        setContentView(R.layout.activity_widget_config)
        findViewById<TextView>(R.id.config_title).text = localized.getString(R.string.config_title)
        findViewById<TextView>(R.id.config_subtitle).text = localized.getString(R.string.config_subtitle)
        findViewById<Button>(R.id.config_select_all).text = localized.getString(R.string.config_select_all)
        findViewById<Button>(R.id.config_clear_all).text = localized.getString(R.string.config_clear_all)
        findViewById<Button>(R.id.config_save).text = localized.getString(R.string.config_save)

        val timetables = availableTimetables(this)
        val timetableList = findViewById<LinearLayout>(R.id.config_timetable_list)
        val density = resources.displayMetrics.density
        val rowMargin = (12 * density).toInt()
        val rowPadding = (14 * density).toInt()
        val accentColor = ContextCompat.getColor(this, R.color.widget_title)
        val textColor = ContextCompat.getColor(this, R.color.widget_text_primary)

        if (timetables.isEmpty()) {
            findViewById<LinearLayout>(R.id.config_actions_row).visibility = ViewGroup.GONE
            findViewById<TextView>(R.id.config_subtitle).text = localized.getString(R.string.config_no_timetables)
            findViewById<Button>(R.id.config_save).text = localized.getString(R.string.config_continue)
        } else {
            val selected = scheduleSelectedTimetables(this, appWidgetId)
            timetables.forEach { (id, name) ->
                val row = LinearLayout(this).apply {
                    orientation = LinearLayout.HORIZONTAL
                    gravity = Gravity.CENTER_VERTICAL
                    background = ContextCompat.getDrawable(context, R.drawable.config_row_background)
                    setPadding(rowPadding, rowPadding, rowPadding, rowPadding)
                    layoutParams = LinearLayout.LayoutParams(
                        ViewGroup.LayoutParams.MATCH_PARENT,
                        ViewGroup.LayoutParams.WRAP_CONTENT,
                    ).apply { setMargins(0, 0, 0, rowMargin) }
                }
                val checkbox = CheckBox(this).apply {
                    text = name
                    isChecked = selected == null || selected.contains(id)
                    tag = id
                    setTextColor(textColor)
                    buttonTintList = ColorStateList.valueOf(accentColor)
                }
                checkboxes.add(checkbox)
                row.addView(checkbox)
                timetableList.addView(row)
            }
        }

        findViewById<Button>(R.id.config_select_all).setOnClickListener {
            checkboxes.forEach { it.isChecked = true }
        }
        findViewById<Button>(R.id.config_clear_all).setOnClickListener {
            checkboxes.forEach { it.isChecked = false }
        }
        findViewById<Button>(R.id.config_save).setOnClickListener { save() }
    }

    private val context get() = this

    private fun save() {
        if (checkboxes.isNotEmpty()) {
            val selectedIds = checkboxes.filter { it.isChecked }.map { it.tag as String }.toSet()
            if (selectedIds.isEmpty()) {
                Toast.makeText(this, localized.getString(R.string.config_select_at_least_one), Toast.LENGTH_SHORT).show()
                return
            }
            setScheduleSelectedTimetables(this, appWidgetId, selectedIds)
        }

        renderScheduleWidget(this, AppWidgetManager.getInstance(this), appWidgetId)

        val resultValue = Intent().putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
        setResult(RESULT_OK, resultValue)
        finish()
    }
}

private fun availableTimetables(context: android.content.Context): List<Pair<String, String>> {
    val raw = HomeWidgetPlugin.getData(context).getString("available_timetables", null)
        ?: return emptyList()
    return raw.split("\n")
        .filter { it.isNotBlank() }
        .mapNotNull { line ->
            val parts = line.split("|", limit = 2)
            if (parts.size == 2) parts[0] to parts[1] else null
        }
}
