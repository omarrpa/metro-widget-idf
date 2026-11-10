// Metro Widget IDF - widget Android (RemoteViews) alimenté par home_widget
// Créé par : Omar Pérez - 2026-11-09 08:10
package com.omarperez.metro_widget

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.net.Uri
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class NextPassWidgetProvider : HomeWidgetProvider() {
    private val rowIds = intArrayOf(R.id.row0, R.id.row1, R.id.row2, R.id.row3, R.id.row4, R.id.row5)
    private val badgeIds = intArrayOf(R.id.badge0, R.id.badge1, R.id.badge2, R.id.badge3, R.id.badge4, R.id.badge5)
    private val destIds = intArrayOf(R.id.dest0, R.id.dest1, R.id.dest2, R.id.dest3, R.id.dest4, R.id.dest5)
    private val taIds = intArrayOf(R.id.t0a, R.id.t1a, R.id.t2a, R.id.t3a, R.id.t4a, R.id.t5a)
    private val tbIds = intArrayOf(R.id.t0b, R.id.t1b, R.id.t2b, R.id.t3b, R.id.t4b, R.id.t5b)

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val now = System.currentTimeMillis()
        var soonest = Long.MAX_VALUE
        var updated = 0L
        for (id in appWidgetIds) {
            val v = RemoteViews(context.packageName, R.layout.next_pass_widget)
            v.setOnClickPendingIntent(
                R.id.widget_root,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
            )
            v.setOnClickPendingIntent(
                R.id.refresh,
                HomeWidgetBackgroundIntent.getBroadcast(context, Uri.parse("metrowidget://refresh")),
            )
            val raw = widgetData.getString("board_json", null)
            if (raw == null) {
                showMessage(v, "Ouvrez l'appli une première fois")
            } else {
                try {
                    val b = JSONObject(raw)
                    updated = b.optLong("updated", 0L)
                    v.setTextViewText(R.id.station, b.optString("station", "—"))
                    v.setTextViewText(
                        R.id.updated,
                        if (updated > 0) SimpleDateFormat("HH:mm", Locale.FRANCE).format(Date(updated)) else "",
                    )
                    val rows = b.optJSONArray("rows")
                    val n = rows?.length() ?: 0
                    if (n == 0) showMessage(v, b.optString("error", "Aucun passage")) else v.setViewVisibility(R.id.message, View.GONE)
                    for (i in rowIds.indices) {
                        if (i >= n) {
                            v.setViewVisibility(rowIds[i], View.GONE)
                            continue
                        }
                        val r = rows!!.getJSONObject(i)
                        v.setViewVisibility(rowIds[i], View.VISIBLE)
                        v.setTextViewText(badgeIds[i], r.optString("line"))
                        v.setInt(badgeIds[i], "setBackgroundColor", parse(r.optString("bg"), "#5A5A5A"))
                        v.setTextColor(badgeIds[i], parse(r.optString("fg"), "#FFFFFF"))
                        v.setTextViewText(destIds[i], r.optString("dest"))
                        val t = r.optJSONArray("t")
                        val a = t?.optLong(0, 0L) ?: 0L
                        val c = t?.optLong(1, 0L) ?: 0L
                        v.setTextViewText(taIds[i], fmt(a, now))
                        v.setTextViewText(tbIds[i], fmt(c, now))
                        if (a > now) soonest = minOf(soonest, a)
                    }
                } catch (e: Exception) {
                    showMessage(v, "Données illisibles")
                }
            }
            appWidgetManager.updateAppWidget(id, v)
        }
        scheduleTick(context, now, updated, soonest)
    }

    private fun showMessage(v: RemoteViews, msg: String) {
        v.setViewVisibility(R.id.message, View.VISIBLE)
        v.setTextViewText(R.id.message, msg)
        for (r in rowIds) v.setViewVisibility(r, View.GONE)
    }

    private fun fmt(t: Long, now: Long): String {
        if (t <= 0L) return ""
        val m = (t - now) / 60000L
        return if (m <= 0) "0" else "$m'"
    }

    private fun parse(c: String, def: String): Int =
        try {
            Color.parseColor(c)
        } catch (e: Exception) {
            Color.parseColor(def)
        }

    private fun scheduleTick(context: Context, now: Long, updated: Long, soonest: Long) {
        val fresh = updated > 0 && now - updated < 30 * 60_000L
        val pending = soonest != Long.MAX_VALUE && soonest - now < 60 * 60_000L
        if (!fresh || !pending) return
        val ids = AppWidgetManager.getInstance(context)
            .getAppWidgetIds(ComponentName(context, NextPassWidgetProvider::class.java))
        val intent = Intent(context, NextPassWidgetProvider::class.java).apply {
            action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
        }
        val pi = PendingIntent.getBroadcast(
            context,
            4242,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val am = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        am.set(AlarmManager.ELAPSED_REALTIME, SystemClock.elapsedRealtime() + 60_000L, pi)
    }
}
