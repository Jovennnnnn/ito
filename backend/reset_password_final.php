<?php
header("Content-Type: application/json");
date_default_timezone_set('Asia/Manila');
require_once 'db_config.php';
require_once 'email_config.php';

// PHPMailer Includes
use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\SMTP;
use PHPMailer\PHPMailer\Exception;

require 'PHPMailer/Exception.php';
require 'PHPMailer/PHPMailer.php';
require 'PHPMailer/SMTP.php';

$data = json_decode(file_get_contents("php://input"));

if (!$data || empty($data->email) || empty($data->otp) || empty($data->password)) {
    echo json_encode(["success" => false, "message" => "Missing required data"]);
    exit;
}

$email = $data->email;
$otp = $data->otp;
$new_password = password_hash($data->password, PASSWORD_BCRYPT);

try {
    // 1. Double check the OTP one last time
    $now = date("Y-m-d H:i:s");
    $query = "SELECT * FROM password_resets WHERE email = ? AND token = ? AND expiry > ?";
    $stmt = $conn->prepare($query);
    $stmt->execute([$email, $otp, $now]);
    $reset = $stmt->fetch();

    if (!$reset) {
        echo json_encode(["success" => false, "message" => "Security verification failed. Please try again."]);
        exit;
    }

    // 2. Update password in 'users' table
    $updateUsers = $conn->prepare("UPDATE users SET password_hash = ? WHERE email = ?");
    $updateUsers->execute([$new_password, $email]);

    // 3. Update password in 'residents' table
    $updateResidents = $conn->prepare("UPDATE residents SET password_hash = ? WHERE email = ?");
    $updateResidents->execute([$new_password, $email]);

    // 4. Clear the token
    $deleteStmt = $conn->prepare("DELETE FROM password_resets WHERE email = ?");
    $deleteStmt->execute([$email]);

    // 5. Send Success Notification Email
    $mail = new PHPMailer(true);
    try {
        $mail->isSMTP();
        $mail->Host       = SMTP_HOST;
        $mail->SMTPAuth   = true;
        $mail->Username   = SMTP_USER;
        $mail->Password   = SMTP_PASS;
        $mail->SMTPSecure = PHPMailer::ENCRYPTION_STARTTLS;
        $mail->Port       = SMTP_PORT;

        $mail->setFrom(SMTP_FROM, SMTP_NAME);
        $mail->addAddress($email);

        $mail->isHTML(true);
        $mail->Subject = 'Password Changed Successfully - Garbage Tracker';
        $mail->Body    = "
            <div style='font-family: Arial, sans-serif; padding: 20px; border: 1px solid #ddd;'>
                <h2 style='color: #27ae60;'>Password Reset Successful</h2>
                <p>Hello,</p>
                <p>Your password for the <strong>Garbage Tracker</strong> app has been successfully updated.</p>
                <p>If you did not perform this action, please contact our support team immediately to secure your account.</p>
                <div style='background: #f9f9f9; padding: 15px; border-radius: 8px; color: #7f8c8d; font-size: 13px;'>
                    Time of Change: " . date("F j, Y, g:i a") . "
                </div>
                <hr style='border: 0; border-top: 1px solid #eee; margin-top: 20px;'>
                <p style='font-size: 12px; color: #bdc3c7;'>This is an automated security notification, please do not reply.</p>
            </div>
        ";

        $mail->send();
    } catch (Exception $e) {
        // We still return success since the DB was updated, but we log the mail failure if needed.
    }

    echo json_encode(["success" => true, "message" => "Password updated successfully"]);

} catch (PDOException $e) {
    echo json_encode(["success" => false, "message" => "Database Error: " . $e->getMessage()]);
}
?>