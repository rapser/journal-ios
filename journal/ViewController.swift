//
//  ViewController.swift
//  journal
//
//  Created by miguel tomairo on 4/10/20.
//  Copyright © 2020 rapser. All rights reserved.
//

import UIKit

struct Post: Codable {
    
    var id: Int
    var title: String
    var postBody: String
}

class Service: NSObject {
    
    static let shared = Service()
    
    func fetchPost(completion: @escaping (Result<[Post],Error>) -> ()){
        
        guard let url = URL(string: "http://192.168.1.5:1337/posts") else {
            return
        }
        
        URLSession.shared.dataTask(with: url) { (data, res, err) in
            
            DispatchQueue.main.async {
                if let err = err{
                    print("no se puede procesar los post", err)
                    return
                }
                
                guard let data = data else {
                    return
                }
                
                do{
                    let posts = try JSONDecoder().decode([Post].self, from: data)
                    completion(.success(posts))
                }catch{
                    completion(.failure(error))
                }
            }
//            print(String(bytes: data, encoding: .utf8) ?? "")
        }.resume()
    }
    
    func createPost(title: String, body: String, completion: @escaping (Error?) -> ()){
        
        guard let url = URL(string: "http://192.168.1.5:1337/post") else {
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        
        let params = ["title": title, "postBody": body]
        
        do {
            let data = try JSONSerialization.data(withJSONObject: params, options: .init())
            
            urlRequest.httpBody = data
            urlRequest.setValue("application/json", forHTTPHeaderField: "content-type")
            
            URLSession.shared.dataTask(with: urlRequest) { (data, res, err) in
                
                guard let data = data else {return}
                print("creado", data)
                completion(nil)
            }.resume()
            
        } catch {
            completion(error)
        }
    }
    
    func deletePost(_ id: Int, completion: @escaping (Error?) -> ()){
        
        guard let url = URL(string: "http://192.168.1.5:1337/post/\(id)") else {
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "DELETE"
                
        URLSession.shared.dataTask(with: urlRequest) { (data, res, err) in
            
            DispatchQueue.main.async {
                if let err = err{
                    print("no se puede eliminar el post", err)
                    return
                }
                
                if let res = res as? HTTPURLResponse, res.statusCode != 200 {
                    
                    let errorString = String(data: data ?? Data(), encoding: .utf8) ?? ""
                    
                    completion(NSError(domain: "", code: res.statusCode, userInfo: [NSLocalizedDescriptionKey: errorString]))
                    
                    return
                }
                
                completion(nil)
            }

        }.resume()
        
    }
}

class ViewController: UITableViewController {
    
    var posts = [Post]()
    
    fileprivate func fetchPost() {
        
        Service.shared.fetchPost { (res) in
            
            switch res {
            case .failure(let err):
                print("fallo el post", err)
            case .success(let posts):
                print(posts)
                self.posts = posts
                self.tableView.reloadData()
            }
        }
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()

    }
    
    func setupUI(){
        
        fetchPost()
        
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.title = "Post"
        navigationItem.rightBarButtonItem = .init(title: "Create post", style: .plain, target: self, action: #selector(handleCreatePost))
    }
    
    @objc fileprivate func handleCreatePost() {
        print("create post")
        
        Service.shared.createPost(title: "ios title", body: "ios post body") { (err) in
            
            if let err = err{
                print("no se puede procesar los post", err)
                return
            }
            
            print("finish creating post")
            self.fetchPost()
        }
    }
    

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return posts.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.textLabel?.text = posts[indexPath.row].title
        cell.detailTextLabel?.text = posts[indexPath.row].postBody
        return cell
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            
            let post = posts[indexPath.row]
            
            Service.shared.deletePost(post.id) { (err) in
                if let err = err{
                     print("no se puede eliminar el post", err)
                     return
                 }
                
                print("eliminacion correcta")
                self.posts.remove(at: indexPath.row)
                self.tableView.deleteRows(at: [indexPath], with: .left)
            }
            
        }
    }

}

