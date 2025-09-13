interface NotificationsProps {
    notifications: string[];
}

export const Notifications = ({ notifications }: NotificationsProps) => {
    return (
        <div className="notifications-container">
            {notifications.map((msg, index) => (
                <div key={index} className="notification">
                    {msg}
                </div>
            ))}
        </div>
    );
};
