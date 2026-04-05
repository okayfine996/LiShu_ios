import Contacts
import ContactsUI
import SwiftUI

struct ContactPickerView: UIViewControllerRepresentable {
    var onSelect: (String, String) -> Void
    var onCancel: () -> Void

    func makeUIViewController(context _: Context) -> ContactPickerHostingController {
        let hosting = ContactPickerHostingController()
        hosting.onSelect = onSelect
        hosting.onCancel = onCancel
        return hosting
    }

    func updateUIViewController(_: ContactPickerHostingController, context _: Context) {}
}

final class ContactPickerHostingController: UIViewController, CNContactPickerDelegate {
    var onSelect: ((String, String) -> Void)?
    var onCancel: (() -> Void)?

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard view.window != nil else { return }

        let picker = CNContactPickerViewController()
        picker.delegate = self
        picker.predicateForEnablingContact = NSPredicate(
            format: "phoneNumbers.@count > 0 OR givenName != '' OR familyName != ''"
        )
        present(picker, animated: true)
    }

    func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
        picker.dismiss(animated: true) { [weak self] in
            let name = [contact.familyName, contact.givenName].filter { !$0.isEmpty }.joined(separator: "")
            let phone = contact.phoneNumbers.first?.value.stringValue ?? ""
            self?.onSelect?(name, phone)
        }
    }

    func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
        picker.dismiss(animated: true) { [weak self] in
            self?.onCancel?()
        }
    }
}
