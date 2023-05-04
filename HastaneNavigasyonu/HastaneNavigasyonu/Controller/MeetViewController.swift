//
//  MeetViewController.swift
//  HastaneNavigasyonu
//
//  Created by Mehmet Akdeniz on 4.05.2023.
//
import CoreData
import UIKit

struct Appointment {
    let hospital: String
    let date: Date
    let time: String

    init(hospital: String, date: Date, time: String) {
        self.hospital = hospital
        self.date = date
        self.time = time
    }

    init(managedObject: NSManagedObject) {
        self.hospital = managedObject.value(forKey: "hospital") as? String ?? ""
        self.date = managedObject.value(forKey: "date") as? Date ?? Date()
        self.time = managedObject.value(forKey: "time") as? String ?? ""
    }
}


class AppointmentTableViewCell: UITableViewCell {
    @IBOutlet weak var hospitalLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
}

class MeetViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    var appointments: [Appointment] = []
    
    override func viewDidLoad() {
            super.viewDidLoad()
            tableView.delegate = self
            tableView.dataSource = self
            fetchAppointments()
        }

        //MARK: TableView
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return appointments.count
        }
        
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "AppointmentCell", for: indexPath) as? AppointmentTableViewCell else {
                fatalError("The dequeued cell is not an instance of AppointmentTableViewCell.")
            }
            let appointment = appointments[indexPath.row]
            cell.hospitalLabel.text = appointment.hospital
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd/MM/yyyy"
            cell.dateLabel.text = dateFormatter.string(from: appointment.date)
            
            cell.timeLabel.text = appointment.time
            
            return cell
        }
        
        @IBAction func addButtonTapped(_ sender: UIButton) {
            let alertController = UIAlertController(title: "Randevu Ekle", message: nil, preferredStyle: .alert)
            alertController.addTextField { textField in
                textField.placeholder = "Hastane Adı"
            }
            alertController.addTextField { textField in
                textField.placeholder = "Tarih (Örn: 01/01/2023)"
            }
            alertController.addTextField { textField in
                textField.placeholder = "Saat (Örn: 14:30)"
            }
            
            let addAction = UIAlertAction(title: "Ekle", style: .default) { [weak self] _ in
                guard let self = self,
                      let hospitalName = alertController.textFields?[0].text,
                      let dateString = alertController.textFields?[1].text,
                      let timeString = alertController.textFields?[2].text,
                      !hospitalName.isEmpty, !dateString.isEmpty, !timeString.isEmpty else {
                    // Hatalı girişleri işlemek için uygun bir kod yazabilirsiniz.
                    return
                }
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "dd/MM/yyyy"
                if let date = dateFormatter.date(from: dateString) {
                    let appointment = Appointment(hospital: hospitalName, date: date, time: timeString)
                    self.saveAppointment(appointment: appointment)
                } else {
                    // Tarih formatı hatalıysa uygun bir hata işlemi gerçekleştirin.
                }
            }
            
            alertController.addAction(addAction)
            alertController.addAction(UIAlertAction(title: "İptal", style:.cancel, handler: nil))
            
            present(alertController, animated: true, completion: nil)
        }
    }



    extension MeetViewController {
        func fetchAppointments() {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "AppointmentEntity")
            
            do {
                let result = try context.fetch(fetchRequest)
                appointments = result.map { Appointment(managedObject: $0) }
                tableView.reloadData()
            } catch let error as NSError {
                print("Could not fetch appointments. \(error), \(error.userInfo)")
            }
        }
        
        func saveAppointment(appointment: Appointment) {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            let entity = NSEntityDescription.entity(forEntityName: "AppointmentEntity", in: context)!
            let managedObject = NSManagedObject(entity: entity, insertInto: context)
            
            managedObject.setValue(appointment.hospital, forKey: "hospital")
            managedObject.setValue(appointment.date, forKey: "date")
            managedObject.setValue(appointment.time, forKey: "time")
            
            do {
                try context.save()
                appointments.append(appointment)
                tableView.reloadData()
            } catch let error as NSError {
                print("Could not save appointment. \(error), \(error.userInfo)")
            }
        }
    }

