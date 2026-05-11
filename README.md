# Online Auction System

A full-stack online auction platform that allows users to securely buy, sell, and bid on products through a web-based marketplace application. The system supports multiple user roles including buyers, sellers, administrators, and customer representatives, each with their own functionalities and dashboards. The project was designed to simulate a real-world auction environment similar to eBay while focusing on secure user interaction, auction management, and database integration.

## Features

### User Authentication & Role Management
- Secure login and session management
- Multiple user roles:
  - Buyer
  - Seller
  - Administrator
  - Customer Representative
- Role-based access control

### Buyer Functionalities
- Browse active auctions
- Place and withdraw bids
- View bidding history
- Purchase won items
- Create and manage alerts for auction items

### Seller Functionalities
- Create and manage auction listings
- Edit and update active auctions
- Monitor bids on listed products
- View sales history and auction performance

### Administrator Functionalities
- Manage customer representatives
- Generate platform reports and analytics
- View earnings reports by item, item type, and user
- Track top buyers and best-selling items
- Monitor overall platform performance

### Customer Representative Functionalities
- Assist users with auction-related issues
- Answer customer questions
- Edit or delete user accounts
- Manage auctions and bids when necessary

## Technologies Used
- Java
- JSP / Servlets
- HTML5
- CSS3
- JavaScript
- MySQL
- JDBC
- Apache Tomcat

## Project Structure

bash
OnlineAuctionSystem/
│
├── META-INF/
├── WEB-INF/
├── web.xml
│
├── Buyer Pages
├── Seller Pages
├── Admin Pages
├── Customer Representative Pages
│
└── Database Connection Files

## How to Run the Project

Prerequisites
Before running the project, make sure the following are installed:

- Java JDK 8 or higher
- Apache Tomcat Server
- MySQL Server
- Eclipse IDE or IntelliJ IDEA

---

1. Clone the Repository
```bash
git clone https://github.com/yourusername/OnlineAuctionSystem.git

2. Import the Project
Eclipse
Open Eclipse
Go to File → Import
Select Existing Projects into Workspace
Choose the cloned project folder
IntelliJ IDEA
Open IntelliJ
Select Open
Choose the project folder

3. Configure Apache Tomcat
Download and install Apache Tomcat
Add Tomcat Server to your IDE
Deploy the project to the Tomcat server

4. Set Up the Database
Open MySQL
Create a new database

- Aunik Manocha


