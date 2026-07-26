use crate::app::App;

impl App {
    pub(super) fn dispatch_pending_clipboard_write(&mut self) -> bool {
        let Some(content) = self.state.request_clipboard_write.take() else {
            return false;
        };
        if self
            .event_tx
            .try_send(crate::events::AppEvent::ClipboardWrite { content })
            .is_err()
        {
            tracing::warn!("failed to queue clipboard write event");
        }
        true
    }
}
