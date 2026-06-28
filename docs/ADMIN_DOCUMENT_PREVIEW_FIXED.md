# Admin Document Preview Fixed

This build improves the Membership Applications review workflow.

## What changed

- Admin can open uploaded verification documents from the dashboard details dialog.
- JPG/PNG images are displayed directly with zoom/pan support.
- PDF documents are displayed inside the dashboard using an in-app PDF viewer.
- Documents are displayed from Base64 data when stored in the database, or from file URLs when the API returns `file_url`.
- The preview supports raw Base64, data-URI Base64, image URLs, and PDF URLs.
- The details dialog now has explicit buttons:
  - Open and preview file
  - Fullscreen view

## Flutter dependency

A PDF viewer dependency was added:

```yaml
syncfusion_flutter_pdfviewer: ^29.2.11
```

Run:

```powershell
cd frontend
flutter pub get
```

before running the app.
