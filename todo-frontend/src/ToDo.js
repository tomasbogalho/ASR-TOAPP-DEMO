import React, { useState, useEffect } from 'react';
import axios from 'axios';

const API_BASE_URL = process.env.REACT_APP_API_BASE_URL;

function ToDo() {
    const [backendIp, setBackendIp] = useState('');
    const [frontendIp, setFrontendIp] = useState('');
    const [tasks, setTasks] = useState([]);
    const [newTask, setNewTask] = useState('');

    useEffect(() => {
        // Fetch backend IP
        axios.get(`${API_BASE_URL}/api/backend-ip`)
            .then(response => {
                setBackendIp(response.data);
            })
            .catch(error => {
                console.error('Error fetching backend IP:', error);
            });

        // Fetch frontend IP
        axios.get('https://api.ipify.org?format=json')
            .then(response => {
                setFrontendIp(response.data.ip);
            })
            .catch(error => {
                console.error('Error fetching frontend IP:', error);
            });
    }, []);

    const handleAddTask = () => {
        if (newTask.trim() !== '') {
            setTasks([...tasks, newTask]);
            setNewTask('');
        }
    };

    return (
        <div>
            <h1>ToDo Application</h1>
            <p>Backend IP: {backendIp}</p>
            <p>Frontend IP: {frontendIp}</p>
            <div>
                <input
                    type="text"
                    value={newTask}
                    onChange={(e) => setNewTask(e.target.value)}
                    placeholder="Add a new task"
                />
                <button onClick={handleAddTask}>Add Task</button>
            </div>
            <ul>
                {tasks.map((task, index) => (
                    <li key={index}>{task}</li>
                ))}
            </ul>
            {/* ... other components and logic ... */}
        </div>
    );
}

export default ToDo;