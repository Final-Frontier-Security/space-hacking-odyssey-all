#include <boost/thread.hpp>
#include <blackboard_hardware_model.hpp>

namespace Nos3
{

    REGISTER_HARDWARE_MODEL(BlackboardHardwareModel,"BLACKBOARD");

    extern ItcLogger::Logger *sim_logger;

    BlackboardHardwareModel::BlackboardHardwareModel(const boost::property_tree::ptree& config) : SimIHardwareModel(config), 
    _enabled(BLACKBOARD_SIM_SUCCESS)
    {
        /* Get the NOS engine connection string */
        std::string connection_string = config.get("common.nos-connection-string", "tcp://127.0.0.1:12001"); 
        sim_logger->info("BlackboardHardwareModel::BlackboardHardwareModel:  NOS Engine connection string: %s.", connection_string.c_str());

        /* Get a data provider */
        std::string dp_name = config.get("simulator.hardware-model.data-provider.type", "BLACKBOARD_PROVIDER");
        _blackboard_dp = SimDataProviderFactory::Instance().Create(dp_name, config);
        sim_logger->info("BlackboardHardwareModel::BlackboardHardwareModel:  Data provider %s created.", dp_name.c_str());

        /* Get on the command bus*/
        std::string time_bus_name = "command";
        if (config.get_child_optional("hardware-model.connections")) 
        {
            /* Loop through the connections for the hardware model */
            BOOST_FOREACH(const boost::property_tree::ptree::value_type &v, config.get_child("hardware-model.connections"))
            {
                /* v.first is the name of the child */
                /* v.second is the child tree */
                if (v.second.get("type", "").compare("time") == 0) // 
                {
                    time_bus_name = v.second.get("bus-name", "command");
                    /* Found it... don't need to go through any more items*/
                    break; 
                }
            }
        }
        _ticks_between_shmem_saves = config.get("simulator.hardware-model.ticks-between-shmem-saves", 10);
        _ticks_to_wait_at_startup = config.get("simulator.hardware-model.ticks-to-wait-at-startup", 1000);
        _time_bus.reset(new NosEngine::Client::Bus(_hub, connection_string, time_bus_name));
        _time_bus->add_time_tick_callback(std::bind(&BlackboardHardwareModel::send_periodic_data_to_shmem, this, std::placeholders::_1));
        sim_logger->info("BlackboardHardwareModel::BlackboardHardwareModel:  Now on time bus named %s.", time_bus_name.c_str());

        _shm_name = config.get("simulator.hardware-model.shared-memory-name", "Blackboard");
        const size_t shm_size = sizeof(BlackboardData);
        bip::shared_memory_object shm(bip::open_or_create, _shm_name.c_str(), bip::read_write);
        shm.truncate(shm_size);
        bip::mapped_region shm_region(shm, bip::read_write);
        _shm_region = std::move(shm_region); // don't let this go out of scope/get destroyed
        _blackboard_data = static_cast<BlackboardData*>(_shm_region.get_address());

        /* Construction complete */
        sim_logger->info("BlackboardHardwareModel::BlackboardHardwareModel:  Construction complete.");
    }


    BlackboardHardwareModel::~BlackboardHardwareModel(void)
    {        
        bip::shared_memory_object::remove(_shm_name.c_str());
        /* Clean up the data provider */
        delete _blackboard_dp;
        _blackboard_dp = nullptr;

        /* The bus will clean up the time node */
    }


    /* Automagically set up by the base class to be called */
    void BlackboardHardwareModel::command_callback(NosEngine::Common::Message msg)
    {
        /* Get the data out of the message */
        NosEngine::Common::DataBufferOverlay dbf(const_cast<NosEngine::Utility::Buffer&>(msg.buffer));
        sim_logger->info("BlackboardHardwareModel::command_callback:  Received command: %s.", dbf.data);

        /* Do something with the data */
        std::string command = dbf.data;
        std::string response = "BlackboardHardwareModel::command_callback:  INVALID COMMAND! (Try HELP)";
        boost::to_upper(command);
        if (command.compare("HELP") == 0) 
        {
            response = "BlackboardHardwareModel::command_callback: Valid commands are HELP, ENABLE, DISABLE, STATUS=X, or STOP";
        }
        else if (command.compare(0,6,"ENABLE") == 0) 
        {
            _enabled = BLACKBOARD_SIM_SUCCESS;
            response = "BlackboardHardwareModel::command_callback:  Enabled\n";
        }
        else if (command.compare(0,7,"DISABLE") == 0) 
        {
            _enabled = BLACKBOARD_SIM_ERROR;
            response = "BlackboardHardwareModel::command_callback:  Disabled";
        }
        else if (command.compare(0,4,"STOP") == 0) 
        {
            _keep_running = false;
            response = "BlackboardHardwareModel::command_callback:  Stopping";
        }
        /* TODO: Add anything additional commands here */

        /* Send a reply */
        sim_logger->info("BlackboardHardwareModel::command_callback:  Sending reply: %s", response.c_str());
        _command_node->send_reply_message_async(msg, response.size(), response.c_str());
    }

    void BlackboardHardwareModel::send_periodic_data_to_shmem(NosEngine::Common::SimTime time)
    {
        if ((time > _ticks_to_wait_at_startup) && ((time % _ticks_between_shmem_saves) == 0)) {
            const boost::shared_ptr<BlackboardDataPoint> data_point =
                boost::dynamic_pointer_cast<BlackboardDataPoint>(_blackboard_dp->get_data_point());
            _blackboard_data->svb[0]       = data_point->get_svb_x();
            _blackboard_data->svb[1]       = data_point->get_svb_y();
            _blackboard_data->svb[2]       = data_point->get_svb_z();
            _blackboard_data->bvb[0]       = data_point->get_bvb_x();
            _blackboard_data->bvb[1]       = data_point->get_bvb_y();
            _blackboard_data->bvb[2]       = data_point->get_bvb_z();
            _blackboard_data->Hvb[0]       = data_point->get_Hvb_x();
            _blackboard_data->Hvb[1]       = data_point->get_Hvb_y();
            _blackboard_data->Hvb[2]       = data_point->get_Hvb_z();
            _blackboard_data->GyroRate[0]  = data_point->get_GyroRate_x();
            _blackboard_data->GyroRate[1]  = data_point->get_GyroRate_y();
            _blackboard_data->GyroRate[2]  = data_point->get_GyroRate_z();
            _blackboard_data->CSSValid[0]  = data_point->get_CSSValid_0();
            _blackboard_data->CSSValid[1]  = data_point->get_CSSValid_1();
            _blackboard_data->CSSValid[2]  = data_point->get_CSSValid_2();
            _blackboard_data->CSSValid[3]  = data_point->get_CSSValid_3();
            _blackboard_data->CSSValid[4]  = data_point->get_CSSValid_4();
            _blackboard_data->CSSValid[5]  = data_point->get_CSSValid_5();
            _blackboard_data->CSSIllum[0]  = data_point->get_CSSIllum_0();
            _blackboard_data->CSSIllum[1]  = data_point->get_CSSIllum_1();
            _blackboard_data->CSSIllum[2]  = data_point->get_CSSIllum_2();
            _blackboard_data->CSSIllum[3]  = data_point->get_CSSIllum_3();
            _blackboard_data->CSSIllum[4]  = data_point->get_CSSIllum_4();
            _blackboard_data->CSSIllum[5]  = data_point->get_CSSIllum_5();
            _blackboard_data->FSSValid     = data_point->get_FSSValid();
            _blackboard_data->FSSSunAng[0] = data_point->get_FSSSunAng_alpha();
            _blackboard_data->FSSSunAng[1] = data_point->get_FSSSunAng_beta();
            _blackboard_data->STValid      = data_point->get_STValid();
            _blackboard_data->STqn[0]      = data_point->get_STqn_0();
            _blackboard_data->STqn[1]      = data_point->get_STqn_1();
            _blackboard_data->STqn[2]      = data_point->get_STqn_2();
            _blackboard_data->STqn[3]      = data_point->get_STqn_3();
            _blackboard_data->AbsTime      = data_point->get_AbsTime();
            _blackboard_data->GPSWeek      = data_point->get_GPSWeek();
            _blackboard_data->GPSSec       = data_point->get_GPSSec();
            _blackboard_data->GPSFracSec   = data_point->get_GPSFracSec();
            _blackboard_data->GPSPosN[0]   = data_point->get_GPSPosN_x();
            _blackboard_data->GPSPosN[1]   = data_point->get_GPSPosN_y();
            _blackboard_data->GPSPosN[2]   = data_point->get_GPSPosN_z();
            _blackboard_data->GPSVelN[0]   = data_point->get_GPSVelN_x();
            _blackboard_data->GPSVelN[1]   = data_point->get_GPSVelN_y();
            _blackboard_data->GPSVelN[2]   = data_point->get_GPSVelN_z();
            _blackboard_data->GPSPosW[0]   = data_point->get_GPSPosW_x();
            _blackboard_data->GPSPosW[1]   = data_point->get_GPSPosW_y();
            _blackboard_data->GPSPosW[2]   = data_point->get_GPSPosW_z();
            _blackboard_data->GPSVelW[0]   = data_point->get_GPSVelW_x();
            _blackboard_data->GPSVelW[2]   = data_point->get_GPSVelW_y();
            _blackboard_data->GPSVelW[1]   = data_point->get_GPSVelW_z();
            _blackboard_data->AccelAcc[0]  = data_point->get_AccelAcc_x();
            _blackboard_data->AccelAcc[1]  = data_point->get_AccelAcc_y();
            _blackboard_data->AccelAcc[2]  = data_point->get_AccelAcc_z();
            _blackboard_data->WhlH[0]      = data_point->get_WhlH_x();
            _blackboard_data->WhlH[1]      = data_point->get_WhlH_y();
            _blackboard_data->WhlH[2]      = data_point->get_WhlH_z();
        }
    }

}
