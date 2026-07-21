# Google Play — Location Permissions Declaration

Use the text below when completing the **Location permissions** and **Foreground service (location)** sections in Google Play Console for **DKT Sales APP**.

Replace `[YOUR_YOUTUBE_VIDEO_URL]` with your uploaded walkthrough link before submitting.

---

## 1. What is the main purpose of your app?

```
DKT Sales APP is a mobile field-sales application for medical and pharmaceutical sales teams. Sales representatives use it to plan daily customer visits, check in and check out at customer locations with GPS, create sales orders, manage inventory, record payments, and track targets. Supervisors use it to monitor team activity and view field staff locations on a live team map. The app is designed for employees working outside the office who need real-time visit and sales tools on their phone.
```

**Shorter alternative (if character limit is tight):**

```
DKT Sales APP helps field sales teams plan customer visits, check in with GPS at visit sites, manage orders and inventory, and lets supervisors track team members on a live map during the workday.
```

---

## 2. Describe 1 location-based feature that needs access to location in the background

```
Live team location sharing for field sales representatives.

When a logged-in sales representative is working in the field, the app periodically sends their device location to the company server so supervisors can see them as “online” on the Team Map. This continues when the app is in the background (for example, while the rep uses another app or locks the screen during travel between customers). A persistent notification is shown on Android (“Location sharing active”) so the user knows location is being shared.

This feature is required because reps are often between visits and not actively using the app, but supervisors still need an accurate view of who is in the field and available. Location is only used for this work-related team visibility and visit-related features—not for advertising or unrelated tracking.

Foreground location is also used when the user taps “Start visit” to attach GPS coordinates to visit check-in, and when opening directions to a customer from a visit.
```

---

## 3. YouTube video walkthrough link

Google requires a short in-app video showing the background location feature described above.

**Paste your link here when ready:**

```
[YOUR_YOUTUBE_VIDEO_URL]
```

### What to record in the video (recommended 1–3 minutes)

1. Log in as a **sales representative**.
2. Show that location permission is requested (While in use / Always).
3. Open the app briefly, then **send it to the background** (home button) or lock the screen.
4. Show the **Android notification**: “Location sharing active — Your location is shared to keep you visible on the live map.”
5. Log in on a second device (or use supervisor account) and open **Team Map** — show the rep appearing online with updated location.
6. Optional: return to the app and **start a visit** to show GPS check-in uses location while the app is in use.

Upload as **Unlisted** on YouTube and paste the URL in Play Console.

---

## 4. FOREGROUND_SERVICE_LOCATION — What tasks require this permission?

**Recommended selection:** ✅ **User-initiated location sharing**

(You may also note in the description that visit check-in uses location while the app is open; the foreground *service* specifically supports ongoing location sharing for the team map.)

### Explanation text for Play Console (if a free-text field is shown)

```
The app uses FOREGROUND_SERVICE_LOCATION to run an ongoing location update while a logged-in sales representative is on duty, so their position can be shared with supervisors on the live Team Map. Android displays a persistent foreground notification (“Location sharing active”) so the user is always aware that location is being collected. This is not silent tracking—the user sees the notification whenever background location sharing is active. The service stops when the user logs out.
```

### Why “User-initiated location sharing” fits

| Option | Use for DKT Sales APP? | Notes |
|--------|------------------------|--------|
| **User-initiated location sharing** | ✅ **Yes — select this** | Rep logs in and works in the field; location is shared for team visibility with a visible notification. |
| Navigation | Partial | Used for opening maps/directions to a customer and visit check-in GPS, but not the main reason for *background* foreground service. |
| Geofencing | ❌ No | App does not use geofences. |
| Other | Optional | Only if Google rejects the above; explain team map live tracking. |

---

## 5. Additional declarations (helpful context)

### Who uses background location?

- **Sales representatives (`salesrep` role):** Location tracking starts after login for team map visibility.
- **Supervisors:** View team locations on Team Map; they do not publish background location the same way.

### When is location collected in the background?

- Periodic updates (approximately every 2–3 minutes) and when the device moves (~80 m).
- Only while the user is **logged in** as a sales rep.
- Stops on **logout**.

### Permissions declared in the app

- `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION` — visit check-in and team map.
- `ACCESS_BACKGROUND_LOCATION` — continue team map updates when app is not in foreground.
- `FOREGROUND_SERVICE` / `FOREGROUND_SERVICE_LOCATION` — Android foreground service with user-visible notification during location sharing.

### Privacy policy reminder

Ensure your privacy policy (linked in Play Console) states:

- What location data is collected (GPS coordinates, timestamps).
- Why (visit verification, supervisor team map, field operations).
- Who can see it (the employee, supervisors/managers).
- How long it is retained.
- That collection stops when the user logs out.

---

## Quick copy-paste summary

| Play Console field | Answer |
|--------------------|--------|
| Main purpose | Field sales app: visits, orders, inventory, supervisor team map |
| Background location feature | Live team location sharing for sales reps with persistent notification |
| YouTube video | `[YOUR_YOUTUBE_VIDEO_URL]` — see recording steps above |
| FOREGROUND_SERVICE_LOCATION task | **User-initiated location sharing** |
