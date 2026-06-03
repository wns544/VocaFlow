import UIKit

final class WordListViewController: UIViewController {
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var filterControl: UISegmentedControl!
    @IBOutlet weak var tableView: UITableView!

    private var filteredWords = WordStore.shared.words

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "단어 목록"
        UIFactory.applyNavigationStyle(to: navigationController)
        setupStoryboardParts()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        filterWords()
    }

    private func setupStoryboardParts() {
        searchBar.placeholder = "단어 검색"
        searchBar.delegate = self
        searchBar.searchBarStyle = .minimal
        filterControl.selectedSegmentIndex = 0
        tableView.dataSource = self
        tableView.delegate = self
    }

    private func filterWords() {
        let query = (searchBar.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        filteredWords = WordStore.shared.words.filter { word in
            let matchesSearch = query.isEmpty
                || word.term.lowercased().contains(query)
                || word.meaning.lowercased().contains(query)
            let matchesState: Bool
            switch filterControl.selectedSegmentIndex {
            case 1:
                matchesState = word.state == .memorized
            case 2:
                matchesState = word.state == .review
            default:
                matchesState = true
            }
            return matchesSearch && matchesState
        }
        title = "단어 목록 \(filteredWords.count)"
        tableView.reloadData()
    }

    @IBAction func stateFilterChanged() {
        filterWords()
    }
}

extension WordListViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        filterWords()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

extension WordListViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filteredWords.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let word = filteredWords[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "WordCell", for: indexPath)
        cell.textLabel?.text = word.term
        cell.detailTextLabel?.text = "\(word.meaning)  ·  \(word.state.rawValue)"
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let word = filteredWords[indexPath.row]
        let detail = storyboard?.instantiateViewController(withIdentifier: "WordDetailViewController") as? WordDetailViewController
            ?? WordDetailViewController()
        detail.configure(word: word)
        navigationController?.pushViewController(detail, animated: true)
    }
}
