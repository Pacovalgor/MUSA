/// Estado de una captura desde el punto de vista del filesystem.
///
/// `pending`: archivo en `MUSA-Inbox/<fecha>/`.
/// `processed`: archivo movido a `MUSA-Inbox/processed/`.
/// `discarded`: archivo movido a `MUSA-Inbox/discarded/`.
/// `unreadable`: archivo presente pero JSON inválido / schemaVersion > 1.
enum InboxCaptureStatus {
  pending,
  processed,
  discarded,
  unreadable,
}
