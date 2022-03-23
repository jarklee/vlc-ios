/*****************************************************************************
 * ChapterView.swift
 *
 * Copyright © 2022 VLC authors and VideoLAN
 * Copyright © 2022 Videolabs
 *
 * Authors: Diogo Simao Marques <diogo.simaomarquespro@gmail.com>
 *
 * Refer to the COPYING file of the official project for license.
 *****************************************************************************/

import UIKit

protocol BookmarksViewDelegate: AnyObject {
    func bookmarksViewGetCurrentPlayingMedia() -> VLCMLMedia?
    func bookmarksViewDidSelectBookmark(value: Float)
    func bookmarksViewDidBeginEditingRow()
    func bookmarksViewDidEndEditingRow()
    func bookmarksViewDisplayAlert(action: BookmarkActionIdentifier, index: Int)
    func bookmarksViewOpenBookmarksView()
}

@objc enum BookmarkActionIdentifier: Int {
    case rename = 1
    case delete
}

class BookmarksView: UIView {
    private let addBookmarkButton = UIButton()
    private let addBookmarkAtTimeButton = UIButton()
    private let bookmarksTableView = UITableView()
    private var isEditing: Bool = false

    weak var delegate: BookmarksViewDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        setupButton()
        setupTable()
        setupConstraints()
        setupTheme()
    }

    func update() {
        bookmarksTableView.reloadData()
        setNeedsLayout()
        layoutIfNeeded()
    }

    func setupTheme() {
        backgroundColor = PresentationTheme.currentExcludingWhite.colors.background
        bookmarksTableView.backgroundColor = PresentationTheme.currentExcludingWhite.colors.background
        update()
    }

    private func setupTable() {
        addSubview(bookmarksTableView)
        bookmarksTableView.delegate = self
        bookmarksTableView.dataSource = self
    }

    private func setupButton() {
        addBookmarkButton.setImage(UIImage(named: "add-bookmark")?.withRenderingMode(.alwaysTemplate), for: .normal)

        addBookmarkButton.imageView?.contentMode = .scaleAspectFit
        addBookmarkButton.tintColor = PresentationTheme.currentExcludingWhite.colors.orangeUI
        addBookmarkButton.addTarget(self, action: #selector(addBookmark), for: .touchUpInside)
        addBookmarkButton.setContentHuggingPriority(.required, for: .horizontal)
        addBookmarkButton.setContentHuggingPriority(.required, for: .vertical)
        addBookmarkButton.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    private func setupConstraints() {
        bookmarksTableView.translatesAutoresizingMaskIntoConstraints = false
        let constraints = [
            bookmarksTableView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            bookmarksTableView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            bookmarksTableView.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            bookmarksTableView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10)
        ]
        NSLayoutConstraint.activate(constraints)
    }

    private func getStringTimeValue(_ value: Int64) -> String {
        let time = VLCTime(number: NSNumber.init(value: value))
        if let stringValue = time?.stringValue {
            return stringValue
        }

        return ""
    }

    @objc private func addBookmark() {
        if let currentMedia = delegate?.bookmarksViewGetCurrentPlayingMedia() {
            let playbackService = PlaybackService.sharedInstance()
            let currentTime = Int64(truncating: playbackService.playedTime().value)
            currentMedia.addBookmark(atTime: currentTime)
            if let bookmark = currentMedia.bookmark(atTime: currentTime) {
                let time = getStringTimeValue(currentTime)
                bookmark.name = NSLocalizedString("BOOKMARK_DEFAULT_NAME", comment: "") + time
            }
            bookmarksTableView.reloadData()
        }
    }

    func deleteBookmarkAt(row: Int) {
        if let currentMedia = delegate?.bookmarksViewGetCurrentPlayingMedia() {
            if let bookmarks = currentMedia.bookmarks {
                if bookmarks.count > row {
                    currentMedia.removeBookmark(atTime: bookmarks[row].time)
                    bookmarksTableView.reloadData()
                }
            }
        }
    }

    func renameBookmarkAt(name: String, row: Int) {
        if let currentMedia = delegate?.bookmarksViewGetCurrentPlayingMedia() {
            if let bookmarks = currentMedia.bookmarks {
                if bookmarks.count > row {
                    if name.isEmpty {
                        var newName = String()
                        let time = getStringTimeValue(bookmarks[row].time)
                        newName = NSLocalizedString("BOOKMARK_DEFAULT_NAME", comment: "") + time
                        bookmarks[row].name = newName
                    } else {
                        bookmarks[row].name = name
                    }
                    bookmarksTableView.reloadData()
                }
            }
        }
    }

    func getBookmarkNameAt(row: Int) -> String {
        if let currentMedia = delegate?.bookmarksViewGetCurrentPlayingMedia() {
            if let bookmarks = currentMedia.bookmarks {
                return bookmarks[row].name
            }
        }
        return ""
    }
}

extension BookmarksView: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    @available(iOS 11.0, *)
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "", handler: { _, _, _ in
            self.delegate?.bookmarksViewDisplayAlert(action: .delete, index: indexPath.row)
        })

        deleteAction.image = UIImage(named: "delete")?.withRenderingMode(.alwaysTemplate)

        let renameAction = UIContextualAction(style: .normal, title: "", handler: { _, _, _ in
            self.delegate?.bookmarksViewDisplayAlert(action: .rename, index: indexPath.row)
        })

        renameAction.backgroundColor = PresentationTheme.currentExcludingWhite.colors.orangeUI
        renameAction.image = UIImage(named: "rename")?.withRenderingMode(.alwaysTemplate)

        return UISwipeActionsConfiguration(actions: [deleteAction, renameAction])
    }

    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteLabel = NSLocalizedString("BUTTON_DELETE", comment: "")
        let deleteAction = UITableViewRowAction(style: .destructive, title: deleteLabel, handler: { _, _ in
            self.delegate?.bookmarksViewDisplayAlert(action: .delete, index: indexPath.row)
        })

        let renameLabel = NSLocalizedString("BUTTON_RENAME", comment: "")
        let renameAction = UITableViewRowAction(style: .normal, title: renameLabel, handler: { _, _ in
            self.delegate?.bookmarksViewDisplayAlert(action: .rename, index: indexPath.row)
        })

        renameAction.backgroundColor = PresentationTheme.currentExcludingWhite.colors.orangeUI

        return [deleteAction, renameAction]
    }

    func tableView(_ tableView: UITableView, willBeginEditingRowAt indexPath: IndexPath) {
        delegate?.bookmarksViewDidBeginEditingRow()
    }

    func tableView(_ tableView: UITableView, didEndEditingRowAt indexPath: IndexPath?) {
        delegate?.bookmarksViewDidEndEditingRow()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let currentMedia = delegate?.bookmarksViewGetCurrentPlayingMedia() {
            if let bookmarks = currentMedia.bookmarks {
                return bookmarks.count
            }
        }
        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()

        let row = indexPath.row

        cell.backgroundColor = PresentationTheme.currentExcludingWhite.colors.background
        cell.textLabel?.textColor = PresentationTheme.currentExcludingWhite.colors.cellTextColor
        cell.selectionStyle = .none

        if let currentMedia = delegate?.bookmarksViewGetCurrentPlayingMedia() {
            if let bookmarks = currentMedia.bookmarks {
                cell.textLabel?.text = bookmarks[row].name
            }
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let currentMedia = delegate?.bookmarksViewGetCurrentPlayingMedia() {
            if let bookmarks = currentMedia.bookmarks {
                let time = bookmarks[indexPath.row].time
                delegate?.bookmarksViewDidSelectBookmark(value: Float(time))
            }
        }
    }
}

extension BookmarksView: ActionSheetAccessoryViewsDelegate {
    func actionSheetAccessoryViews(_ actionSheet: ActionSheetSectionHeader) -> [UIView] {
        return [addBookmarkButton]
    }
}