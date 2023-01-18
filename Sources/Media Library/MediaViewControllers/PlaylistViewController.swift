/*****************************************************************************
 * VLCPlaylistViewController.swift
 * VLC for iOS
 *****************************************************************************
 * Copyright (c) 2018 VideoLAN. All rights reserved.
 * $Id$
 *
 * Authors: Carola Nitz <caro # videolan.org>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/
import UniformTypeIdentifiers

protocol AddItemToPlaylistViewDelegate {
    func handleAddFilesToPlaylist()
    func handleAddFolderToPlaylist()
}

class PlaylistViewController: MediaViewController {
    override init(services: Services) {
        super.init(services: services)
        setupUI()
    }

    private func setupUI() {
        title = NSLocalizedString("PLAYLISTS", comment: "")
        tabBarItem = UITabBarItem(
            title: NSLocalizedString("PLAYLISTS", comment: ""),
            image: UIImage(named: "Playlist"),
            selectedImage: UIImage(named: "Playlist"))
        tabBarItem.accessibilityIdentifier = VLCAccessibilityIdentifier.playlist
    }

    override func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        return [
            PlaylistCategoryViewController(services)
        ]
    }

    func resetTitleView() {
        navigationItem.titleView = nil
    }
}

// MARK: - AddItemToPlaylistViewDelegate
extension PlaylistCategoryViewController: AddItemToPlaylistViewDelegate {
    func handleAddFilesToPlaylist() {
        if #available(iOS 14.0, *) {
            openDocumentPicker(contentTypes: [.item])
        } else {
            openDocumentPicker(documentTypes: ["public.item"])
        }
    }

    func handleAddFolderToPlaylist() {
        if #available(iOS 14.0, *) {r
            openDocumentPicker(contentTypes: [.folder])
        } else {
            openDocumentPicker(documentTypes: ["public.folder"])
        }
    }
    
    @available(iOS 14.0, *)
    private func openDocumentPicker(contentTypes: [UTType]) {
        let vc = UIDocumentPickerViewController(forOpeningContentTypes: contentTypes)
        vc.allowsMultipleSelection = true
        vc.delegate = self
        present(vc, animated: true, completion: nil)
    }
    
    private func openDocumentPicker(documentTypes: [String]) {
        let vc = UIDocumentPickerViewController(documentTypes: documentTypes, in: .open)
        if #available(iOS 11.0, *) {
            vc.allowsMultipleSelection = true
        }
        vc.delegate = self
        present(vc, animated: true, completion: nil)
    }
}

// MARK: Document pickers delete
extension PlaylistCategoryViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt documents: [URL]) {
        print(documents)
        
    }
}
