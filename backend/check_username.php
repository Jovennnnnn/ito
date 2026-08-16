<?php
header("Content-Type: application/json");
require_once 'db_config.php';

$username = $_POST['username'] ?? null;

if ($username) {
    try {
        // Check in users table
        $query1 = "SELECT 1 FROM users WHERE username = ?";
        $stmt1 = $conn->prepare($query1);
        $stmt1->execute([$username]);

        // Check in residents table (assuming they might have usernames too or checking against user table is enough)
        // Usually usernames are in the main 'users' table if linked.

        if ($stmt1->fetch()) {
            echo json_encode(["success" => true, "message" => "Username exists"]);
        } else {
            echo json_encode(["success" => false, "message" => "Username available"]);
        }
    } catch (PDOException $e) {
        echo json_encode(["success" => false, "message" => "Error: " . $e->getMessage()]);
    }
} else {
    echo json_encode(["success" => false, "message" => "No username provided"]);
}
?>
