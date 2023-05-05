//
//  SearchViewController.swift
//  HastaneNavigasyonu
//
//  Created by Mehmet Akdeniz on 4.05.2023.
//

import UIKit


class SearchViewController: UIViewController {

    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableview: UITableView!
    
    var hospitals: [Hospital] = [] // Bu, hastanelerinizi depolamak için kullanılacak
    var filteredHospitals: [Hospital] = [] // Bu, arama sonuçlarını depolamak için kullanılacak
    
    var selectedHospital: Hospital?
        var selectedDate: Date?
        var selectedTime: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        loadHospitalsFromFile()
        tableview.delegate = self
        tableview.dataSource = self
        searchBar.delegate = self
       
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showRoute" {
            if let indexPath = tableview.indexPathForSelectedRow {
                let selectedHospital = filteredHospitals[indexPath.row]
                let mapViewController = segue.destination as! MapViewController
                mapViewController.selectedHospitalCoordinate = selectedHospital.coordinate
            }
        }
    }
}

// MARK: - UITableViewDelegate & UITableViewDataSource
extension SearchViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredHospitals.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "HospitalCell")
        let hospital = filteredHospitals[indexPath.row]
        cell.textLabel?.text = hospital.name
        cell.detailTextLabel?.text = "Hastane"
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "showRoute", sender: self)
    }
}

// MARK: - UISearchBarDelegate
extension SearchViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            filteredHospitals = hospitals
        } else {
            filteredHospitals = hospitals.filter { hospital in
                return hospital.name.lowercased().contains(searchText.lowercased())
            }
        }
        tableview.reloadData()
    }
}

// MARK: - Load Hospitals from File
extension SearchViewController {
    func loadHospitalsFromFile() {
        if let url = Bundle.main.url(forResource: "hospitals", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                hospitals = try JSONDecoder().decode([Hospital].self, from: data)
                filteredHospitals = hospitals
                tableview.reloadData()
            } catch {
                print("Error loading hospitals from file: \(error)")
            }
        } else {
            print("Hospitals file not found")
        }
    }
}
