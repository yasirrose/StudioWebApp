// events.jsx
import { useEffect, useState } from 'react';
import { useTasks } from '/hooks/tasks';

export const useEvents = () => {
    const [events, setEvents] = useState([]);
    // const clientId = localStorage.getItem('clientId');
    const { Tasks, setTasks, loading, error  } = useTasks();

    function parseTaskDateTime(taskDate, taskTime) {
        // Parse the date and time parts separately
        const datePart = new Date(taskDate);
        const timePart = new Date(taskTime);
      
        // Combine them: set the hours and minutes from timePart to datePart
        if (!isNaN(datePart) && !isNaN(timePart)) {
          datePart.setHours(timePart.getHours());
          datePart.setMinutes(timePart.getMinutes());
          datePart.setSeconds(timePart.getSeconds());
        } else {
          console.error("Invalid date or time provided");
          return null;
        }
      
        return datePart;
    }

    useEffect(() => {
    if (Tasks) {
        console.log("-IN USEEFFECT TASKS = ",Tasks);
        
        const mappedEvents = Tasks.map(task => {
            // Usage in events.jsx
            // console.log("-IN MAPPED TASKS = ",task);
            // if (task.task_start_date.length > 0) {
            //     debugger
            //     console.log("TASK START DATE IS NULL");
            // }
            
            const startDateTime = parseTaskDateTime(task.task_start_date, task.task_start_time);
            const endDateTime = parseTaskDateTime(task.task_end_date, task.task_end_time);

            const statusColors = {
                1: '#d4d216',
                2: '#0d6efd',
                3: '#17c653',
                4: '#17c653',
                5: '#17c653' 
            };


            return {
                event_id: task.task_id,
                admin_id: task.project_id,
                title: task.task_name,
                start: startDateTime,
                end: endDateTime,
                color: statusColors[task.status_id] || '#000000',
                description: task.description,
                editable: true,
                deletable: true,
                allDay: task.is_all_day == 1 ? true : false,
                // isAllDay: task.is_all_day,
            };
        });

        setEvents(mappedEvents);
    }
    }, [Tasks]);

    return { events, loading, error };
};

