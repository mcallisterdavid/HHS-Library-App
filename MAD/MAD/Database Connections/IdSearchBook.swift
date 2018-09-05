import Foundation
import UIKit

//Protocol that allows for asynchronous code, allowing other code to function even if network issues causes delays in the information download
protocol DownloadProtocol: class {
    func itemsDownloaded(items: NSArray, from: String)
}

class IdSearchBook: NSObject {
    
    
    
    weak var delegate: DownloadProtocol!
    
    let urlPath = "http://www.the-library-database.com/hhs_php/isbn_book.php"
    //Downloads book matching that isbn
    func downloadItems(isbn: String) {
        
        
         let url = URL(string: urlPath)!
         var request = URLRequest(url: url)
         request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
         request.httpMethod = "POST"
         let postString = "password=secureAf&isbn=\(isbn)"
         request.httpBody = postString.data(using: .utf8)
         let task = URLSession.shared.dataTask(with: request) { data, response, error in
         guard let data = data, error == nil else {                                                 // check for fundamental networking error
            print("error=\(String(describing: error))")
         return
         }
         
         if let httpStatus = response as? HTTPURLResponse, httpStatus.statusCode != 200 {           // check for http errors
         print("statusCode should be 200, but is \(httpStatus.statusCode)")
            print("response = \(String(describing: response))")
         }
         
            _ = String(data: data, encoding: .utf8)
            self.parseJSON(data)
         }
         task.resume()

    }
    
    //Parses retrieved JSON
    func parseJSON(_ data:Data) {

        var jsonResult = NSArray()
        
        do{
            jsonResult = try JSONSerialization.jsonObject(with: data, options:JSONSerialization.ReadingOptions.allowFragments) as! NSArray
            
        } catch let error as NSError {
            print(error)
            
        }
//        print(data)
        print("Length")
        print(jsonResult.count)
        
        //NSArrays initialized
        var jsonElement = NSDictionary()
        let books = NSMutableArray()
        
        for i in 0 ..< jsonResult.count
        {

            jsonElement = jsonResult[i] as! NSDictionary
            
            let book = BookModel()
  
            
            //JsonElement values are guaranteed to not be null through optional binding
            if let name = jsonElement["Title"] as! String?,
                let isbn = jsonElement["isbn"] as! String?,
                let authorID = jsonElement["Author"] as! String?,
                let desc = jsonElement["description"] as! String?,
                let bookcount = jsonElement["bookcount"] as! String?,
                let booktotal = jsonElement["Total Copies"] as! String?,
                let image_url = jsonElement["picture_html"] as! String?,
                let id = jsonElement["id"] as! String?
            {
                book.db_id = id
                book.name = name
                book.title = name
                book.ISBN = isbn
                book.author = authorID
                book.desc = desc
                book.bookCount = Int(bookcount)
                book.googleImageURL = image_url
                book.getRating()
                if let url = URL(string: image_url)
                {
                    
                    book.downloadCoverImage(url: url)
                }
                book.bookTotal = Int(booktotal)
            }
                        
            books.add(book)
            
        }
        
        DispatchQueue.main.async(execute: { () -> Void in
            if self.delegate != nil
            {
            self.delegate.itemsDownloaded(items: books, from: "idSearch")
            }
        })
    }
    
}

