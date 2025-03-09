// struct out interface & function
#[derive(Copy, Drop, Serde, starknet::Store)]
struct Student {
    name: felt252,
    grade: felt252,
}

// interface
#[starknet::interface]
pub trait IClassroom<TContractState> {
    fn add_student(ref self: TContractState, student_id: felt252, name: felt252, grade: felt252); // write to state
    fn update_student(
        ref self: TContractState, name: felt252, student_id: felt252, upgrade: felt252 // write to state
    );
    fn get_student(self: @TContractState, student_id: felt252) -> Student; // read from state
}

// contract
#[starknet::contract]
pub mod Classroom {
    use starknet::event::EventEmitter; // import for events
    use super::{IClassroom, Student}; // import interface classroom and struct student
    use core::starknet::{
        get_caller_address, ContractAddress,
        storage::{Map, StorageMapReadAccess, StorageMapWriteAccess} // import map
    };

    // storage
    #[storage]
    struct Storage {
        students: Map<felt252, Student>, // map student ID to struct Student
        teacher: ContractAddress // Has admin rights
    }

    //StudentsAdded struct
    #[derive(Drop, starknet::Event)]
    struct StudentsAdded {
        name: felt252,
        student_id: felt252,
        grade: felt252,
    }

    // StudentsGradeUpdated struct
    #[derive(Drop, starknet::Event)]
    struct StudentsGradeUpdated {
        name: felt252,
        student_id: felt252,
        upgrade: felt252,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        StudentsAdded: StudentsAdded,
        StudentsGradeUpdated: StudentsGradeUpdated
    }

    // constructor set teacher as contract address (contract owner)
    #[constructor]
    fn constructor(ref self: ContractState, teacher: ContractAddress) {
        self.teacher.write(teacher)
    }

    #[abi(embed_v0)]
    impl ClassroomImpl of IClassroom<ContractState> {
        fn add_student(
            ref self: ContractState, student_id: felt252, name: felt252, grade: felt252
        ) {
            let teacher_address = self.teacher.read();
            assert(get_caller_address() == teacher_address, 'Only Teacher can add record'); // modifier: Only teacher is authorized
            let student = Student { name: name, grade: grade, }; // add student
            self.students.write(student_id, student);
            self.emit(StudentsAdded { name, student_id, grade });
        } 
 
        fn update_student(
            ref self: ContractState, name: felt252, student_id: felt252, upgrade: felt252
        ) {
            let teacher_address = self.teacher.read();
            // assert(bool, felt252)
            assert(get_caller_address() == teacher_address, 'Cannot update student record');
            let mut student = self.students.read(student_id);
            // student = Student {
            //     name: name,
            //     grade: upgrade
            // };

            student.grade = upgrade;
            self.students.write(student_id, student);
            self.emit(StudentsGradeUpdated { name, student_id, upgrade })
        }

        fn get_student(self: @ContractState, student_id: felt252) -> Student {
            self.students.read(student_id)
        }
    }
}


